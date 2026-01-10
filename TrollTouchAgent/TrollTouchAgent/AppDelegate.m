//
//  AppDelegate.m
//  TrollTouchAgent
//

#import "AppDelegate.h"
#import "AgentServer.h"
#import <AVFoundation/AVFoundation.h>

@interface AppDelegate ()
@property(nonatomic, strong) AVAudioPlayer *audioPlayer;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  NSLog(@"[Agent] 🚀 TrollTouchAgent Starting...");

  // 创建简单的 UI
  self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  self.window.backgroundColor = [UIColor blackColor];

  UIViewController *rootVC = [[UIViewController alloc] init];
  rootVC.view.backgroundColor = [UIColor blackColor];

  UILabel *label = [[UILabel alloc]
      initWithFrame:CGRectMake(20, 100, self.window.bounds.size.width - 40,
                               200)];
  label.text = @"TrollTouchAgent\n\n运行中...\n\nHTTP Server: localhost:8100";
  label.textColor = [UIColor whiteColor];
  label.textAlignment = NSTextAlignmentCenter;
  label.numberOfLines = 0;
  label.font = [UIFont systemFontOfSize:18];
  [rootVC.view addSubview:label];

  self.window.rootViewController = rootVC;
  [self.window makeKeyAndVisible];

  // 启动后台保活
  [self startBackgroundKeepAlive];

  // 启动 HTTP Server
  [[AgentServer sharedServer] startServerOnPort:8100];

  NSLog(@"[Agent] ✅ Agent initialization complete");

  return YES;
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
