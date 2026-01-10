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

  UILabel *label = [[UILabel alloc]
      initWithFrame:CGRectMake(20, 100, self.window.bounds.size.width - 40,
                               200)];
  label.text = @"TrollTouchAgent\n\n运行中...\n\nApp Groups IPC Ready\n\nCheck "
               @"Console for Self-Test";
  label.textColor = [UIColor whiteColor];
  label.textAlignment = NSTextAlignmentCenter;
  label.numberOfLines = 0;
  label.font = [UIFont systemFontOfSize:16];
  [rootVC.view addSubview:label];

  self.window.rootViewController = rootVC;
  [self.window makeKeyAndVisible];

  // 启动后台保活
  [self startBackgroundKeepAlive];

  // 启动 App Groups 监听
  [self startCommandListener];

  // 运行自测试
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC),
                 dispatch_get_main_queue(), ^{
                   [AgentSelfTest runAllTests];
                 });

  NSLog(@"[Agent] ✅ Agent initialization complete");

  return YES;
}

- (void)startCommandListener {
  FileLogger *logger = [FileLogger sharedLogger];
  [logger log:@"[Agent] 👂 Starting App Groups command listener..."];

  [[SharedCommandQueue sharedQueue] startListeningWithHandler:^(
                                        NSDictionary *command) {
    [logger log:[NSString stringWithFormat:@"[Agent] 📥 Received command: %@",
                                           command]];
    [self handleCommand:command];
  }];

  [logger log:@"[Agent] ✅ Command listener started"];
}

- (void)handleCommand:(NSDictionary *)command {
  FileLogger *logger = [FileLogger sharedLogger];

  NSString *action = command[@"action"];
  NSString *commandId = command[@"commandId"];

  [logger log:[NSString
                  stringWithFormat:@"[Agent] 📥 Handling command: %@ (ID: %@)",
                                   action, commandId]];

  BOOL success = NO;
  NSString *errorMessage = nil;

  if ([action isEqualToString:@"tap"]) {
    CGFloat x = [command[@"x"] floatValue];
    CGFloat y = [command[@"y"] floatValue];
    [logger
        log:[NSString
                stringWithFormat:@"[Agent] 👆 Executing tap at (%.3f, %.3f)", x,
                                 y]];
    success = [[TouchInjector sharedInjector] tapAtPoint:CGPointMake(x, y)];
    [logger log:[NSString stringWithFormat:@"[Agent] %@ Tap result: %@",
                                           success ? @"✅" : @"❌",
                                           success ? @"SUCCESS" : @"FAILED"]];
  } else if ([action isEqualToString:@"swipe"]) {
    CGFloat x1 = [command[@"x1"] floatValue];
    CGFloat y1 = [command[@"y1"] floatValue];
    CGFloat x2 = [command[@"x2"] floatValue];
    CGFloat y2 = [command[@"y2"] floatValue];
    CGFloat duration = [command[@"duration"] floatValue];
    [logger log:[NSString stringWithFormat:@"[Agent] 👉 Executing swipe from "
                                           @"(%.3f, %.3f) to (%.3f, %.3f)",
                                           x1, y1, x2, y2]];
    success = [[TouchInjector sharedInjector] swipeFrom:CGPointMake(x1, y1)
                                                     to:CGPointMake(x2, y2)
                                               duration:duration];
    [logger log:[NSString stringWithFormat:@"[Agent] %@ Swipe result: %@",
                                           success ? @"✅" : @"❌",
                                           success ? @"SUCCESS" : @"FAILED"]];
  } else {
    errorMessage = @"Unknown action";
    [logger log:[NSString
                    stringWithFormat:@"[Agent] ❌ Unknown action: %@", action]];
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
}

- (void)startBackgroundKeepAlive {
  NSLog(@"[Agent] 🔊 Starting background keep-alive...");

  // 配置音频会话
  AVAudioSession *session = [AVAudioSession sharedInstance];
  NSError *error = nil;
  [session setCategory:AVAudioSessionCategoryPlayback
           withOptions:AVAudioSessionCategoryOptionMixWithOthers
                 error:&error];
  if (error) {
    NSLog(@"[Agent] ❌ Audio session error: %@", error);
    return;
  }
  [session setActive:YES error:&error];

  // 播放静音音频
  NSString *soundPath = [[NSBundle mainBundle] pathForResource:@"silence"
                                                        ofType:@"mp3"];
  if (!soundPath) {
    // 如果没有音频文件,创建一个空的播放器
    NSLog(@"[Agent] ⚠️ No silence.mp3 found, using alternative method");
    return;
  }

  NSURL *soundURL = [NSURL fileURLWithPath:soundPath];
  self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:soundURL
                                                            error:&error];
  if (error) {
    NSLog(@"[Agent] ❌ Audio player error: %@", error);
    return;
  }

  self.audioPlayer.numberOfLoops = -1; // 无限循环
  self.audioPlayer.volume = 0.01;      // 极低音量
  [self.audioPlayer play];

  NSLog(@"[Agent] ✅ Background keep-alive started");
}

- (void)applicationWillResignActive:(UIApplication *)application {
  NSLog(@"[Agent] ⚠️ Will resign active");
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
  NSLog(@"[Agent] 📱 Entered background - Server should continue running");
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
  NSLog(@"[Agent] 📱 Will enter foreground");
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
  NSLog(@"[Agent] ✅ Did become active");
}

@end
