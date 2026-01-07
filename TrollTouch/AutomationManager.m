#import "AutomationManager.h"
#import "ScreenCapture.h"
#import "TouchSimulator.h"
#import "VisionHelper.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>
#import <dlfcn.h> // Required for dlopen, dlsym, RTLD_LAZY
#import <objc/runtime.h>
#import <sys/utsname.h>

#define TIKTOK_GLOBAL @"com.zhiliaoapp.musically" // Restored macro
#define TIKTOK_CHINA @"com.ss.iphone.ugc.Aweme"
#define TIKTOK_BUNDLE_ID @"com.zhiliaoapp.musically" // Kept for safety
typedef int (*SBSLaunchAppFunc)(CFStringRef identifier, Boolean suspended);

@implementation AutomationManager {
  NSThread *_workerThread;
  AVAudioPlayer *_silentPlayer;
  UIWindow *_floatingWindow;
  CLLocationManager *_locManager;
  UIBackgroundTaskIdentifier _bgTask;
}

+ (instancetype)sharedManager {
  static AutomationManager *shared = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
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

  printf("%s\n", [msg UTF8String]);

  if (self.logHandler) {
    dispatch_async(dispatch_get_main_queue(), ^{
      self.logHandler(msg);
    });
  }
}

- (void)showFloatingWindow {
  dispatch_async(dispatch_get_main_queue(), ^{
    if (!_floatingWindow) {
      _floatingWindow = [[UIWindow alloc]
          initWithFrame:CGRectMake(
                            0, 0, [UIScreen mainScreen].bounds.size.width, 24)];
      _floatingWindow.windowLevel = UIWindowLevelAlert + 1000;
      _floatingWindow.backgroundColor =
          [[UIColor blackColor] colorWithAlphaComponent:0.7];
      _floatingWindow.userInteractionEnabled = NO;
      _floatingWindow.rootViewController =
          [UIViewController new]; // Required for iOS 9+

      UILabel *lbl = [[UILabel alloc] initWithFrame:_floatingWindow.bounds];
      lbl.text = @"TrollTouch 正在运行中... (保活生效)";
      lbl.textColor = [UIColor greenColor];
      lbl.textAlignment = NSTextAlignmentCenter;
      lbl.font = [UIFont boldSystemFontOfSize:12];
      [_floatingWindow addSubview:lbl];
    }
    _floatingWindow.hidden = NO;
    [_floatingWindow makeKeyAndVisible];
  });
}

- (void)hideFloatingWindow {
  dispatch_async(dispatch_get_main_queue(), ^{
    _floatingWindow.hidden = YES;
    _floatingWindow = nil;
  });
}

- (void)setupBackgrounds {
  // 1. Audio (Existing)
  NSError *err = nil;
  [[AVAudioSession sharedInstance]
      setCategory:AVAudioSessionCategoryPlayback
      withOptions:AVAudioSessionCategoryOptionMixWithOthers
            error:&err];
  [[AVAudioSession sharedInstance] setActive:YES error:&err];

  if (!_silentPlayer) {
    NSMutableData *data = [NSMutableData dataWithLength:44100 * 2];
    _silentPlayer = [[AVAudioPlayer alloc] initWithData:data
                                           fileTypeHint:AVFileTypeWAVE
                                                  error:&err];
    _silentPlayer.numberOfLoops = -1;
    _silentPlayer.volume = 0.0;
    [_silentPlayer prepareToPlay];
  }
  [_silentPlayer play];

  // 2. Location (New Strong Keep-Alive)
  if (!_locManager) {
    _locManager = [[CLLocationManager alloc] init];
    _locManager.allowsBackgroundLocationUpdates = YES;
    _locManager.pausesLocationUpdatesAutomatically = NO;
    _locManager.desiredAccuracy =
        kCLLocationAccuracyThreeKilometers; // Low power
    [_locManager requestAlwaysAuthorization];
  }
  [_locManager startUpdatingLocation];

  // 3. Background Task Assertion
  _bgTask = [[UIApplication sharedApplication]
      beginBackgroundTaskWithExpirationHandler:^{
        [[UIApplication sharedApplication] endBackgroundTask:self->_bgTask];
        self->_bgTask = UIBackgroundTaskInvalid;
      }];

  [self log:@"[系统] 强效后台保活(音频+定位) 已启动"];
}

- (void)startAutomation {
  if (self.config.isRunning)
    return;

  [self setupBackgrounds];
  [self showFloatingWindow];

  self.config = (TrollConfig){.startHour = self.config.startHour,
                              .endHour = self.config.endHour,
                              .minWatchSec = self.config.minWatchSec,
                              .maxWatchSec = self.config.maxWatchSec,
                              .swipeJitter = self.config.swipeJitter,
                              .isRunning = YES};

  [self log:@"[*] 自动化服务已启动..."];

  _workerThread = [[NSThread alloc] initWithTarget:self
                                          selector:@selector(automationLoop)
                                            object:nil];
  [_workerThread start];
}

- (void)stopAutomation {
  if (!self.config.isRunning)
    return;

  [self log:@"[*] 正在停止自动化服务..."];

  if (_silentPlayer)
    [_silentPlayer stop];
  if (_locManager)
    [_locManager stopUpdatingLocation];
  if (_bgTask != UIBackgroundTaskInvalid) {
    [[UIApplication sharedApplication] endBackgroundTask:_bgTask];
    _bgTask = UIBackgroundTaskInvalid;
  }

  [self hideFloatingWindow];

  TrollConfig newConfig = self.config;
  newConfig.isRunning = NO;
  self.config = newConfig;

  [_workerThread cancel];
  _workerThread = nil;
}

- (BOOL)isRunning {
  return self.config.isRunning;
}

// --- 逻辑 ---

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
}

- (void)performLike {
  [self log:@"[*] 执行点赞 (双击)"];
  perform_touch(0.5, 0.5);
  usleep(100000);
  perform_touch(0.5, 0.5);
}

// 关注操作逻辑
- (void)performFollow {
  // 关注按钮坐标大致在 (0.93, 0.36) - 用户头像下的加号
  [self log:@"[*] 执行关注 (点击头像下加号)..."];
  perform_touch(0.93, 0.36);
}

- (float)randFloat:(float)min max:(float)max {
  return min + ((float)arc4random() / UINT32_MAX) * (max - min);
}

- (void)performHumanSwipe {
  float jitter = self.config.swipeJitter;
  float startX = [self randFloat:0.5 - jitter max:0.5 + jitter];
  float startY = [self randFloat:0.7 - jitter max:0.8 + jitter];
  float endX = startX + [self randFloat:-0.1 max:0.1];
  float endY = [self randFloat:0.2 max:0.3];
  float duration = [self randFloat:0.12 max:0.18];

  [self log:@"[*] 滑动: (%.2f, %.2f) -> (%.2f, %.2f)", startX, startY, endX,
            endY];
  perform_swipe(startX, startY, endX, endY, duration);
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
    if (![self isWorkingHour]) {
      [self log:@"[-] 非工作时间，暂停5分钟..."];
      [NSThread sleepForTimeInterval:300];
      continue;
    }

    // --- 状态检测 ---
    UIImage *screen = captureScreen();
    if (screen) {
      BOOL isFeed = isVideoFeed(screen);
      if (!isFeed) {
        [self log:@"[!] 警告: 视觉检测显示当前可能不在视频推荐页。"];
        // 尝试自动纠正：点击首页
        // perform_touch(0.08, 0.93);
      }
    }

    count++;
    [self log:@"\n--- 视频 #%d ---", count];

    // --- 自动发布 (每50个视频) ---
    if (count % 50 == 0) {
      [self performAutoPublish];
      continue;
    }

    // --- OCR 查房 (每15个视频) ---
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
