//
//  AppDelegate.m
//  TrollTouchAgent
//

#import "AppDelegate.h"
#import "AgentSelfTest.h"
#import "FileLogger.h"
#import "SharedCommandQueue.h"
#import "TouchInjector.h"
#import <AVFoundation/AVFoundation.h>


@interface AppDelegate ()
@property(nonatomic, strong) AVAudioPlayer *audioPlayer;
@property(nonatomic, strong) UITextView *logTextView;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  // Initialize FileLogger first
  FileLogger *logger = [FileLogger sharedLogger];
  [logger log:@"[Agent] 🚀 TrollTouchAgent Starting..."];

  // 创建简单的 UI
  self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  self.window.backgroundColor = [UIColor blackColor];

  UIViewController *rootVC = [[UIViewController alloc] init];
  rootVC.view.backgroundColor = [UIColor blackColor];

  // Title Label
  UILabel *label = [[UILabel alloc]
      initWithFrame:CGRectMake(20, 60, self.window.bounds.size.width - 40, 80)];
  label.text = @"TrollTouchAgent\n运行中...\nApp Groups IPC Ready";
  label.textColor = [UIColor whiteColor];
  label.textAlignment = NSTextAlignmentCenter;
  label.numberOfLines = 0;
  label.font = [UIFont boldSystemFontOfSize:16];
  [rootVC.view addSubview:label];

  // Log TextView - 显示实时日志
  CGFloat logY = 150;
  self.logTextView = [[UITextView alloc]
      initWithFrame:CGRectMake(10, logY, self.window.bounds.size.width - 20,
                               self.window.bounds.size.height - logY - 20)];
  self.logTextView.backgroundColor = [UIColor colorWithWhite:0.1 alpha:1.0];
  self.logTextView.textColor = [UIColor greenColor];
  self.logTextView.font = [UIFont fontWithName:@"Menlo" size:10];
  self.logTextView.editable = NO;
  self.logTextView.text = @"";
  [rootVC.view addSubview:self.logTextView];

  self.window.rootViewController = rootVC;
  [self.window makeKeyAndVisible];

  // 添加日志到 UI
  [self addLog:@"[Agent] 🚀 TrollTouchAgent Starting..."];
  [self addLog:[NSString stringWithFormat:@"[Agent] 📁 Log file: %@",
                                          [logger getLogPath] ?: @"FAILED"]];

  // 启动后台保活
  [self startBackgroundKeepAlive];

  // 启动 App Groups 监听
  [self startCommandListener];

  // 运行自测试
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC),
                 dispatch_get_main_queue(), ^{
                   [AgentSelfTest runAllTests];
                 });

  [logger log:@"[Agent] ✅ Agent initialization complete"];
  [self addLog:@"[Agent] ✅ Agent initialization complete"];

  return YES;
}

- (void)addLog:(NSString *)message {
  dispatch_async(dispatch_get_main_queue(), ^{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm:ss"];
    NSString *timestamp = [formatter stringFromDate:[NSDate date]];
    NSString *logEntry =
        [NSString stringWithFormat:@"[%@] %@\n", timestamp, message];

    self.logTextView.text =
        [self.logTextView.text stringByAppendingString:logEntry];

    // Auto-scroll to bottom
    NSRange range = NSMakeRange(self.logTextView.text.length - 1, 1);
    [self.logTextView scrollRangeToVisible:range];
  });
}

- (void)startCommandListener {
  FileLogger *logger = [FileLogger sharedLogger];
  [logger log:@"[Agent] 👂 Starting App Groups command listener..."];
  [self addLog:@"[Agent] 👂 Starting command listener..."];

  [[SharedCommandQueue sharedQueue] startListeningWithHandler:^(
                                        NSDictionary *command) {
    [logger log:[NSString stringWithFormat:@"[Agent] 📥 Received command: %@",
                                           command]];
    [self addLog:[NSString
                     stringWithFormat:@"📥 Command: %@", command[@"action"]]];
    [self handleCommand:command];
  }];

  [logger log:@"[Agent] ✅ Command listener started"];
  [self addLog:@"[Agent] ✅ Listener started"];
}

- (void)handleCommand:(NSDictionary *)command {
  FileLogger *logger = [FileLogger sharedLogger];

  NSString *action = command[@"action"];
  NSString *commandId = command[@"commandId"];

  [logger log:[NSString
                  stringWithFormat:@"[Agent] 📥 Handling command: %@ (ID: %@)",
                                   action, commandId]];
  [self addLog:[NSString stringWithFormat:@"🔧 Handling: %@", action]];

  BOOL success = NO;
  NSString *errorMessage = nil;

  if ([action isEqualToString:@"tap"]) {
    CGFloat x = [command[@"x"] floatValue];
    CGFloat y = [command[@"y"] floatValue];
    [logger
        log:[NSString
                stringWithFormat:@"[Agent] 👆 Executing tap at (%.3f, %.3f)", x,
                                 y]];
    [self addLog:[NSString stringWithFormat:@"👆 Tap: (%.2f, %.2f)", x, y]];
    success = [[TouchInjector sharedInjector] tapAtPoint:CGPointMake(x, y)];
    [logger log:[NSString stringWithFormat:@"[Agent] %@ Tap result: %@",
                                           success ? @"✅" : @"❌",
                                           success ? @"SUCCESS" : @"FAILED"]];
    [self addLog:[NSString stringWithFormat:@"%@ Tap: %@",
                                            success ? @"✅" : @"❌",
                                            success ? @"OK" : @"FAIL"]];
  } else if ([action isEqualToString:@"swipe"]) {
    CGFloat x1 = [command[@"x1"] floatValue];
    CGFloat y1 = [command[@"y1"] floatValue];
    CGFloat x2 = [command[@"x2"] floatValue];
    CGFloat y2 = [command[@"y2"] floatValue];
    CGFloat duration = [command[@"duration"] floatValue];
    [logger log:[NSString stringWithFormat:@"[Agent] 👉 Executing swipe from "
                                           @"(%.3f, %.3f) to (%.3f, %.3f)",
                                           x1, y1, x2, y2]];
    [self
        addLog:[NSString stringWithFormat:@"👉 Swipe: (%.2f,%.2f)→(%.2f,%.2f)",
                                          x1, y1, x2, y2]];
    success = [[TouchInjector sharedInjector] swipeFrom:CGPointMake(x1, y1)
                                                     to:CGPointMake(x2, y2)
                                               duration:duration];
    [logger log:[NSString stringWithFormat:@"[Agent] %@ Swipe result: %@",
                                           success ? @"✅" : @"❌",
                                           success ? @"SUCCESS" : @"FAILED"]];
    [self addLog:[NSString stringWithFormat:@"%@ Swipe: %@",
                                            success ? @"✅" : @"❌",
                                            success ? @"OK" : @"FAIL"]];
  } else {
    errorMessage = @"Unknown action";
    [logger log:[NSString
                    stringWithFormat:@"[Agent] ❌ Unknown action: %@", action]];
    [self addLog:[NSString stringWithFormat:@"❌ Unknown: %@", action]];
  }

  // Send response
  NSDictionary *response = @{
    @"commandId" : commandId,
    @"success" : @(success),
    @"error" : errorMessage ?: @""
  };

  [[SharedCommandQueue sharedQueue] sendResponse:response];
  [logger log:[NSString
                  stringWithFormat:@"[Agent] 📤 Response sent: %@ (success=%d)",
                                   commandId, success]];
  [self addLog:[NSString stringWithFormat:@"📤 Response sent: %@",
                                          success ? @"✅" : @"❌"]];
}

- (void)startBackgroundKeepAlive {
  [self addLog:@"[Agent] 🔊 Starting background keep-alive..."];
  NSLog(@"[Agent] 🔊 Starting background keep-alive...");

  // 配置音频会话
  AVAudioSession *session = [AVAudioSession sharedInstance];
  NSError *error = nil;
  [session setCategory:AVAudioSessionCategoryPlayback
           withOptions:AVAudioSessionCategoryOptionMixWithOthers
                 error:&error];
  if (error) {
    NSLog(@"[Agent] ❌ Audio session error: %@", error);
    [self addLog:[NSString stringWithFormat:@"❌ Audio error: %@",
                                            error.localizedDescription]];
    return;
  }
  [session setActive:YES error:&error];

  [self addLog:@"[Agent] ✅ Background keep-alive started"];
    NSLog(@"[Agent] ✅ Background keep-alive started (no audio file needed)"];
}

- (void)applicationWillResignActive:(UIApplication *)application {
  [self addLog:@"[Agent] ⚠️ Will resign active"];
  NSLog(@"[Agent] ⚠️ Will resign active");
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
  [self addLog:@"[Agent] 📱 Entered background"];
    NSLog(@"[Agent] 📱 Entered background - Server should continue running"];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
  [self addLog:@"[Agent] 📱 Will enter foreground"];
  NSLog(@"[Agent] 📱 Will enter foreground");
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
  [self addLog:@"[Agent] ✅ Did become active"];
  NSLog(@"[Agent] ✅ Did become active");
}

@end
