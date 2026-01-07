#import "AutomationManager.h"
#import "ScreenCapture.h"
#import "TouchSimulator.h"
#import "VisionHelper.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>
#import <dlfcn.h> // Required for dlopen, dlsym, RTLD_LAZY
#import <objc/runtime.h>
#import <signal.h>
#import <stdlib.h>
#import <sys/utsname.h>

#define TIKTOK_GLOBAL @"com.zhiliaoapp.musically" // Restored macro
#define TIKTOK_CHINA @"com.ss.iphone.ugc.Aweme"
#define TIKTOK_BUNDLE_ID @"com.zhiliaoapp.musically" // Kept for safety
typedef int (*SBSLaunchAppFunc)(CFStringRef identifier, Boolean suspended);

@implementation AutomationManager {
  NSThread *_workerThread;
  AVAudioRecorder *_audioRecorder;
  UIBackgroundTaskIdentifier _bgTask;
  UIWindow *_overlayWindow;
  NSTimer *_windowKeepAliveTimer;
}

// Log Path Helper - Public Downloads for easy access via Files app / 3uTools
NSString *getLogDirectory() {
  NSString *path = @"/var/mobile/Media/Downloads/TrollTouch_Logs";
  NSFileManager *fm = [NSFileManager defaultManager];
  if (![fm fileExistsAtPath:path]) {
    [fm createDirectoryAtPath:path
        withIntermediateDirectories:YES
                         attributes:nil
                              error:nil];
  }
  return path;
}

// Crash & Log Handling
void uncaughtExceptionHandler(NSException *exception) {
  NSString *logPath =
      [getLogDirectory() stringByAppendingPathComponent:@"crash.log"];
  NSString *content = [NSString
      stringWithFormat:@"CRASH EXCEPTION: %@\nReason: %@\nStack: %@\n\n",
                       exception.name, exception.reason,
                       exception.callStackSymbols];

  // Append to file
  FILE *f = fopen([logPath UTF8String], "a");
  if (f) {
    fprintf(f, "%s", [content UTF8String]);
    fclose(f);
  }
}

void signalHandler(int signal) {
  NSString *logPath =
      [getLogDirectory() stringByAppendingPathComponent:@"crash.log"];
  NSString *content =
      [NSString stringWithFormat:@"CRASH SIGNAL: %d\nStack: %@\n\n", signal,
                                 [NSThread callStackSymbols]];

  FILE *f = fopen([logPath UTF8String], "a");
  if (f) {
    fprintf(f, "%s", [content UTF8String]);
    fclose(f);
  }
  exit(signal);
}

+ (instancetype)sharedManager {
  static AutomationManager *shared = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    // Setup Global Logging
    NSString *logDir = getLogDirectory();
    NSString *logPath = [logDir stringByAppendingPathComponent:@"app.log"];

    // Redirect stdout/stderr to log file so we capture printf from C files too
    freopen([logPath UTF8String], "a+", stdout);
    freopen([logPath UTF8String], "a+", stderr);

    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    signal(SIGSEGV, signalHandler);
    signal(SIGABRT, signalHandler);
    signal(SIGILL, signalHandler);

    shared = [[AutomationManager alloc] init];
    shared.config = (TrollConfig){.startHour = 9,
                                  .endHour = 23,
                                  .minWatchSec = 3,
                                  .maxWatchSec = 8,
                                  .swipeJitter = 0.05,
                                  .isRunning = NO};
    init_touch_system();
  });
  return shared;
}

- (void)log:(NSString *)format, ... {
  va_list args;
  va_start(args, format);
  NSString *msg = [[NSString alloc] initWithFormat:format arguments:args];
  va_end(args);

  // Print to stdout (which is now redirected to file)
  NSString *tsMsg = [NSString stringWithFormat:@"[%@] %@", [NSDate date], msg];
  printf("%s\n", [tsMsg UTF8String]);
  fflush(stdout); // Ensure immediate write

  // UI Callback
  if (self.logHandler) {
    dispatch_async(dispatch_get_main_queue(), ^{
      self.logHandler(msg);
    });
  }
}

- (void)setupNotifications {
  UNUserNotificationCenter *center =
      [UNUserNotificationCenter currentNotificationCenter];
  [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert +
                                           UNAuthorizationOptionSound +
                                           UNAuthorizationOptionBadge)
                        completionHandler:^(BOOL granted,
                                            NSError *_Nullable error) {
                          if (granted) {
                            printf("[System] Notifications granted\n");
                          }
                        }];
}

- (void)sendNotification:(NSString *)title body:(NSString *)body {
  UNMutableNotificationContent *content =
      [[UNMutableNotificationContent alloc] init];
  content.title = title;
  content.body = body;
  content.sound = nil; // Silent update

  UNTimeIntervalNotificationTrigger *trigger =
      [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:0.1
                                                         repeats:NO];
  UNNotificationRequest *request =
      [UNNotificationRequest requestWithIdentifier:[[NSUUID UUID] UUIDString]
                                           content:content
                                           trigger:trigger];

  [[UNUserNotificationCenter currentNotificationCenter]
      addNotificationRequest:request
       withCompletionHandler:nil];
}

- (void)setupPiPWindow {
  if (_overlayWindow)
    return;

  dispatch_async(dispatch_get_main_queue(), ^{
    CGRect screenBounds = [[UIScreen mainScreen] bounds];

    // Create small PiP window in bottom-right corner
    CGFloat pipWidth = 80;
    CGFloat pipHeight = 120;
    CGFloat margin = 10;
    CGRect pipFrame =
        CGRectMake(screenBounds.size.width - pipWidth - margin,
                   screenBounds.size.height - pipHeight - margin - 50, pipWidth,
                   pipHeight);

    self->_overlayWindow = [[UIWindow alloc] initWithFrame:pipFrame];
    self->_overlayWindow.windowLevel = UIWindowLevelAlert + 1;
    self->_overlayWindow.backgroundColor = [UIColor colorWithWhite:0.1
                                                             alpha:0.85];
    self->_overlayWindow.layer.cornerRadius = 12;
    self->_overlayWindow.layer.borderWidth = 2;
    self->_overlayWindow.layer.borderColor =
        [UIColor colorWithRed:0 green:1 blue:0 alpha:0.8].CGColor;
    self->_overlayWindow.clipsToBounds = YES;

    // Status indicator
    UILabel *statusIcon =
        [[UILabel alloc] initWithFrame:CGRectMake(0, 10, pipWidth, 30)];
    statusIcon.text = @"🤖";
    statusIcon.font = [UIFont systemFontOfSize:24];
    statusIcon.textAlignment = NSTextAlignmentCenter;
    [self->_overlayWindow addSubview:statusIcon];

    // Status text
    UILabel *statusLabel =
        [[UILabel alloc] initWithFrame:CGRectMake(5, 45, pipWidth - 10, 40)];
    statusLabel.text = @"运行中";
    statusLabel.font = [UIFont boldSystemFontOfSize:12];
    statusLabel.textColor = [UIColor colorWithRed:0 green:1 blue:0 alpha:1];
    statusLabel.textAlignment = NSTextAlignmentCenter;
    statusLabel.numberOfLines = 2;
    statusLabel.tag = 1000;
    [self->_overlayWindow addSubview:statusLabel];

    // Counter label
    UILabel *counterLabel =
        [[UILabel alloc] initWithFrame:CGRectMake(5, 85, pipWidth - 10, 30)];
    counterLabel.text = @"0 操作";
    counterLabel.font = [UIFont systemFontOfSize:10];
    counterLabel.textColor = [UIColor whiteColor];
    counterLabel.textAlignment = NSTextAlignmentCenter;
    counterLabel.tag = 1001;
    [self->_overlayWindow addSubview:counterLabel];

    self->_overlayWindow.hidden = NO;
    [self->_overlayWindow makeKeyAndVisible];

    [self log:@"[系统] PiP 控制窗口已创建"];
  });
}

- (void)updateOverlayAlpha:(CGFloat)alpha {
  if (!_overlayWindow)
    return;
  dispatch_async(dispatch_get_main_queue(), ^{
    // Only update the status bar alpha, keep window at 1.0
    UIView *statusBar = [self->_overlayWindow viewWithTag:999];
    if (statusBar) {
      statusBar.backgroundColor = [UIColor colorWithRed:1.0
                                                  green:0.0
                                                   blue:0.0
                                                  alpha:alpha];
    }
    [self log:@"[系统] 覆盖窗口透明度已更新: %.2f", alpha];
  });
}

- (void)removeOverlayWindow {
  if (!_overlayWindow)
    return;

  // Stop keep-alive timer
  if (_windowKeepAliveTimer) {
    [_windowKeepAliveTimer invalidate];
    _windowKeepAliveTimer = nil;
  }

  dispatch_async(dispatch_get_main_queue(), ^{
    self->_overlayWindow.hidden = YES;
    self->_overlayWindow = nil;
    [self log:@"[系统] 透明覆盖窗口已移除"];
  });
}

- (void)setupBackgrounds {
  // 1. Audio Recording (Aggressive Keep-Alive)
  NSError *err = nil;
  AVAudioSession *session = [AVAudioSession sharedInstance];
  [session setCategory:AVAudioSessionCategoryPlayAndRecord
           withOptions:AVAudioSessionCategoryOptionMixWithOthers |
                       AVAudioSessionCategoryOptionDuckOthers
                 error:&err];
  [session setActive:YES error:&err];

  if (!_audioRecorder) {
    NSURL *url = [NSURL fileURLWithPath:@"/dev/null"];
    NSDictionary *settings = @{
      AVFormatIDKey : @(kAudioFormatAppleLossless),
      AVSampleRateKey : @44100.0f,
      AVNumberOfChannelsKey : @1,
      AVEncoderAudioQualityKey : @(AVAudioQualityMin)
    };
    _audioRecorder = [[AVAudioRecorder alloc] initWithURL:url
                                                 settings:settings
                                                    error:&err];
    [_audioRecorder prepareToRecord];
  }
  [_audioRecorder record];

  // 2. Background Task
  _bgTask = [[UIApplication sharedApplication]
      beginBackgroundTaskWithExpirationHandler:^{
        [[UIApplication sharedApplication] endBackgroundTask:self->_bgTask];
        self->_bgTask = UIBackgroundTaskInvalid;
      }];

  [self log:@"[系统] 录音后台保活已启动"];
}

- (void)startAutomation {
  if (self.config.isRunning)
    return;

  [self setupNotifications];
  [self setupBackgrounds];
  [self setupOverlayWindow];
  [self sendNotification:@"TrollTouch" body:@"自动化服务已启动 (前台模式)"];

  self.config = (TrollConfig){.startHour = self.config.startHour,
                              .endHour = self.config.endHour,
                              .minWatchSec = self.config.minWatchSec,
                              .maxWatchSec = self.config.maxWatchSec,
                              .swipeJitter = self.config.swipeJitter,
                              .isRunning = YES};

  [self log:@"[*] 自动化服务已启动..."];

  CGRect screenRect = [UIScreen mainScreen].bounds;
  CGFloat scale = [UIScreen mainScreen].scale;
  [self
      log:@"[设备信息] 屏幕尺寸: %.0fx%.0f (Scale: %.1f) - 实际像素: %.0fx%.0f",
          screenRect.size.width, screenRect.size.height, scale,
          screenRect.size.width * scale, screenRect.size.height * scale];

  _workerThread = [[NSThread alloc] initWithTarget:self
                                          selector:@selector(automationLoop)
                                            object:nil];
  [_workerThread start];
}

- (void)stopAutomation {
  if (!self.config.isRunning)
    return;

  [self log:@"[*] 正在停止自动化服务..."];

  [self removeOverlayWindow];

  if (_audioRecorder)
    [_audioRecorder stop];
  if (_bgTask != UIBackgroundTaskInvalid) {
    [[UIApplication sharedApplication] endBackgroundTask:_bgTask];
    _bgTask = UIBackgroundTaskInvalid;
  }

  [self sendNotification:@"TrollTouch" body:@"自动化服务已停止"];

  TrollConfig newConfig = self.config;
  newConfig.isRunning = NO;
  self.config = newConfig;

  [_workerThread cancel];
  _workerThread = nil;
}

- (BOOL)isRunning {
  return self.config.isRunning;
}

- (void)launchTikTok {
  [self log:@"[*] 正在启动 TikTok..."];
  void *handle = dlopen("/System/Library/PrivateFrameworks/"
                        "SpringBoardServices.framework/SpringBoardServices",
                        RTLD_LAZY);
  if (!handle)
    return;

  SBSLaunchAppFunc SBSLaunchApplicationWithIdentifier =
      (SBSLaunchAppFunc)dlsym(handle, "SBSLaunchApplicationWithIdentifier");
  if (SBSLaunchApplicationWithIdentifier) {
    SBSLaunchApplicationWithIdentifier((__bridge CFStringRef)TIKTOK_GLOBAL,
                                       false);
    [NSThread sleepForTimeInterval:1.0];
    SBSLaunchApplicationWithIdentifier((__bridge CFStringRef)TIKTOK_CHINA,
                                       false);
  }
  dlclose(handle);

  // Critical: Re-show overlay window after TikTok launches
  [NSThread sleepForTimeInterval:2.0];
  [self ensureOverlayVisible];
}

- (void)ensureOverlayVisible {
  if (!_overlayWindow)
    return;

  dispatch_async(dispatch_get_main_queue(), ^{
    if (self->_overlayWindow) {
      self->_overlayWindow.hidden = NO;
      [self->_overlayWindow makeKeyAndVisible];

      // Force window to stay on top
      self->_overlayWindow.windowLevel = UIWindowLevelAlert + 2;

      [self log:@"[系统] 覆盖窗口已重新显示"];
    }
  });
}

- (void)performLike {
  [self log:@"[*] 执行点赞 (坐标: 0.50, 0.50)"];
  [self setupBackgrounds];
  perform_touch(0.5, 0.5);
  [NSThread sleepForTimeInterval:0.1];
  perform_touch(0.5, 0.5);
}

// 关注操作逻辑
- (void)performFollow {
  [self log:@"[*] 执行关注 (坐标: 0.93, 0.36)"];
  [self setupBackgrounds];
  perform_touch(0.93, 0.36);
}

- (float)randFloat:(float)min max:(float)max {
  return min + ((float)arc4random() / UINT32_MAX) * (max - min);
}

- (void)performHumanSwipe {
  [self setupBackgrounds];

  // Cast to int to prevent unsigned underflow when subtracting
  float startX = 0.5f + ((int)arc4random_uniform(20) - 10) / 100.0f;
  float startY = 0.8f + ((int)arc4random_uniform(10) - 5) / 100.0f;

  float endX = startX + ((int)arc4random_uniform(10) - 5) / 100.0f;
  float endY = 0.2f + ((int)arc4random_uniform(10) - 5) / 100.0f;

  [self log:@"[*] 执行滑动: (%.2f, %.2f) -> (%.2f, %.2f) 时长: 0.3s", startX,
            startY, endX, endY];
  perform_swipe(startX, startY, endX, endY, 0.3);
}

- (BOOL)isWorkingHour {
  NSDate *now = [NSDate date];
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSInteger hour = [calendar component:NSCalendarUnitHour fromDate:now];

  if (self.config.startHour <= self.config.endHour) {
    return (hour >= self.config.startHour && hour < self.config.endHour);
  } else {
    return (hour >= self.config.startHour || hour < self.config.endHour);
  }
}

// 功能 6: 自动发布宏
- (void)performAutoPublish {
  [self log:@"[*] --- 开始自动发布流程 ---"];

  // 1. 点击 '+' (底部中间)
  [self log:@"[*] 点击 '+'..."];
  perform_touch(0.5, 0.93);
  [NSThread sleepForTimeInterval:2.5];

  // 2. 点击 '上传' (底部右侧)
  [self log:@"[*] 点击 '上传'..."];
  perform_touch(0.85, 0.85);
  [NSThread sleepForTimeInterval:2.5];

  // 3. 选择第1个视频 (左上角)
  [self log:@"[*] 选择第一个视频..."];
  perform_touch(0.16, 0.20);
  [NSThread sleepForTimeInterval:1.5];

  // 4. 点击 下一步 (底部右侧)
  [self log:@"[*] 点击 '下一步'..."];
  perform_touch(0.85, 0.93);
  [NSThread sleepForTimeInterval:4.0];

  // 5. 点击 下一步 (编辑页)
  [self log:@"[*] 点击 '下一步' (编辑页)..."];
  perform_touch(0.85, 0.93);
  [NSThread sleepForTimeInterval:3.0];

  // 6. 点击 发布
  [self log:@"[*] 点击 '发布' !"];
  perform_touch(0.85, 0.93);
  [NSThread sleepForTimeInterval:5.0];

  [self log:@"[*] 自动发布完成。"];

  // 返回推荐页 (点击左下角首页)
  perform_touch(0.08, 0.93);
  [NSThread sleepForTimeInterval:2.0];
}

- (void)automationLoop {
  // 5秒倒计时启动
  for (int i = 5; i > 0; i--) {
    [self log:@"[*] %d秒后开始执行...", i];
    [NSThread sleepForTimeInterval:1.0];
    if (!self.config.isRunning)
      return;
  }

  [self launchTikTok];
  [NSThread sleepForTimeInterval:5.0];

  int count = 0;
  while (self.config.isRunning && ![[NSThread currentThread] isCancelled]) {

    NSDate *now = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSInteger hour = [calendar component:NSCalendarUnitHour fromDate:now];

    // Check working hours
    if (hour < self.config.startHour || hour >= self.config.endHour) {
      [self log:@"[休息中] 当前 %ld点 (工作时间: %d-%d)", (long)hour,
                self.config.startHour, self.config.endHour];
      [self sendNotification:@"TrollTouch"
                        body:[NSString stringWithFormat:@"[休息中] 当前 %ld点",
                                                        (long)hour]];
      [NSThread sleepForTimeInterval:60.0];
      continue;
    }

    // --- 状态检测 (已禁用截图以防止后台崩溃) ---
    /*
    UIImage *screen = captureScreen();
    if (screen) {
      BOOL isFeed = isVideoFeed(screen);
      if (!isFeed) {
        [self log:@"[!] 警告: 视觉检测显示当前可能不在视频推荐页。"];
        // 尝试自动纠正：点击首页
        // perform_touch(0.08, 0.93);
      }
    }
    */

    count++;
    [self log:@"\n--- 视频 #%d ---", count];

    // --- 自动发布 (每50个视频) ---
    if (count % 50 == 0) {
      [self performAutoPublish];
      continue;
    }

    /*
    // --- OCR 查房 (每15个视频) - 已禁用
    if (count % 15 == 0) {
      [self log:@"[*] 检查个人主页数据 (OCR)..."];
      // 左滑进入主页
      perform_swipe(0.8, 0.5, 0.2, 0.5, 0.3);
      [NSThread sleepForTimeInterval:2.0];

      UIImage *profileImg = captureScreen();
      if (profileImg) {
        recognizeText(profileImg, ^(NSString *res) {
          if (res) {
            NSString *log = [res stringByReplacingOccurrencesOfString:@"\n"
                                                           withString:@" | "];
            if (log.length > 60)
              log = [log substringToIndex:60];
            [self log:@"[OCR 识别结果] %@", log];
          }
        });
      }
      // 右滑返回
      [NSThread sleepForTimeInterval:2.0];
      perform_swipe(0.2, 0.5, 0.8, 0.5, 0.3);
    }
    */

    // 随机观看时长
    int interval = self.config.maxWatchSec - self.config.minWatchSec;
    if (interval < 1)
      interval = 1;
    int watchTime = self.config.minWatchSec + (arc4random() % interval);
    [self log:@"[*] 观看 %d 秒...", watchTime];
    [NSThread sleepForTimeInterval:watchTime];

    if (!self.config.isRunning)
      break;

    // 随机点赞
    if (arc4random() % 2 == 0) {
      [self performLike];
      [NSThread sleepForTimeInterval:[self randFloat:0.5 max:1.5]];
    }

    // 随机关注 (10% 概率)
    if (arc4random() % 10 == 0) {
      [self performFollow];
      [NSThread sleepForTimeInterval:1.0];
    }

    if (!self.config.isRunning)
      break;

    // 滑动到下一个
    [self performHumanSwipe];
    [NSThread sleepForTimeInterval:[self randFloat:1.0 max:2.0]];
  }

  [self log:@"[*] 自动化线程已停止。"];
}

@end
