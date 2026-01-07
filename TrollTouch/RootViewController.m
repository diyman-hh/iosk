//
//  RootViewController.m
//  TrollTouch (Simplified - One Button Start)
//

#import "RootViewController.h"
#import "AutomationManager.h"

@implementation RootViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  self.view.backgroundColor = [UIColor colorWithRed:0.95
                                              green:0.95
                                               blue:0.97
                                              alpha:1.0];

  CGFloat w = self.view.bounds.size.width;
  CGFloat y = 100;

  // Title
  UILabel *titleLabel =
      [[UILabel alloc] initWithFrame:CGRectMake(20, y, w - 40, 50)];
  titleLabel.text = @"🤖 TrollTouch";
  titleLabel.font = [UIFont boldSystemFontOfSize:32];
  titleLabel.textAlignment = NSTextAlignmentCenter;
  [self.view addSubview:titleLabel];
  y += 70;

  // Subtitle
  UILabel *subtitle =
      [[UILabel alloc] initWithFrame:CGRectMake(20, y, w - 40, 30)];
  subtitle.text = @"TikTok 自动化工具";
  subtitle.font = [UIFont systemFontOfSize:16];
  subtitle.textColor = [UIColor grayColor];
  subtitle.textAlignment = NSTextAlignmentCenter;
  [self.view addSubview:subtitle];
  y += 60;

  // Start button
  UIButton *startButton = [UIButton buttonWithType:UIButtonTypeSystem];
  startButton.frame = CGRectMake(40, y, w - 80, 70);
  [startButton setTitle:@"🚀 启动自动化" forState:UIControlStateNormal];
  startButton.titleLabel.font = [UIFont boldSystemFontOfSize:24];
  startButton.backgroundColor = [UIColor colorWithRed:0.2
                                                green:0.8
                                                 blue:0.4
                                                alpha:1.0];
  [startButton setTitleColor:[UIColor whiteColor]
                    forState:UIControlStateNormal];
  startButton.layer.cornerRadius = 16;
  [startButton addTarget:self
                  action:@selector(startAutomation)
        forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:startButton];
  y += 90;

  // Stop button
  UIButton *stopButton = [UIButton buttonWithType:UIButtonTypeSystem];
  stopButton.frame = CGRectMake(40, y, w - 80, 50);
  [stopButton setTitle:@"⏹ 停止" forState:UIControlStateNormal];
  stopButton.titleLabel.font = [UIFont boldSystemFontOfSize:18];
  stopButton.backgroundColor = [UIColor colorWithRed:0.9
                                               green:0.3
                                                blue:0.3
                                               alpha:1.0];
  [stopButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  stopButton.layer.cornerRadius = 12;
  [stopButton addTarget:self
                 action:@selector(stopAutomation)
       forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:stopButton];
  y += 70;

  // Info
  UITextView *info =
      [[UITextView alloc] initWithFrame:CGRectMake(20, y, w - 40, 250)];
  info.editable = NO;
  info.font = [UIFont systemFontOfSize:14];
  info.backgroundColor = [UIColor clearColor];
  info.text = @"📱 功能说明\n\n"
              @"• 自动刷 TikTok 视频\n"
              @"• 随机点赞和关注\n"
              @"• 模拟真人操作\n"
              @"• 后台运行支持\n\n"
              @"📊 日志位置\n\n"
              @"日志保存在:\n"
              @"/var/mobile/Documents/app.log\n\n"
              @"可以通过文件管理器查看\n"
              @"或使用 idevicesyslog 实时查看\n\n"
              @"⚠️ 注意事项\n\n"
              @"• 确保 TikTok 已安装\n"
              @"• 首次运行需要授权\n"
              @"• 建议连接充电器";
  [self.view addSubview:info];
}

- (void)startAutomation {
  NSLog(@"[UI] 用户点击启动");

  if ([[AutomationManager sharedManager] isRunning]) {
    [self showAlert:@"提示" message:@"自动化已在运行中"];
    return;
  }

  UIAlertController *alert = [UIAlertController
      alertControllerWithTitle:@"🚀 启动自动化"
                       message:@"即将启动 TikTok "
                               @"自动化\n\n日志保存在:\n/var/mobile/Documents/"
                               @"app.log"
                preferredStyle:UIAlertControllerStyleAlert];

  [alert addAction:[UIAlertAction
                       actionWithTitle:@"开始"
                                 style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction *_Nonnull action) {
                                 [[AutomationManager sharedManager]
                                     startAutomation];
                                 [self showToast:@"✅ 自动化已启动"];
                               }]];

  [alert addAction:[UIAlertAction actionWithTitle:@"取消"
                                            style:UIAlertActionStyleCancel
                                          handler:nil]];

  [self presentViewController:alert animated:YES completion:nil];
}

- (void)stopAutomation {
  NSLog(@"[UI] 用户点击停止");
  [[AutomationManager sharedManager] stopAutomation];
  [self showToast:@"⏹ 自动化已停止"];
}

- (void)showAlert:(NSString *)title message:(NSString *)message {
  UIAlertController *alert =
      [UIAlertController alertControllerWithTitle:title
                                          message:message
                                   preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:@"确定"
                                            style:UIAlertActionStyleDefault
                                          handler:nil]];
  [self presentViewController:alert animated:YES completion:nil];
}

- (void)showToast:(NSString *)message {
  UILabel *toast = [[UILabel alloc]
      initWithFrame:CGRectMake(40, self.view.bounds.size.height - 150,
                               self.view.bounds.size.width - 80, 50)];
  toast.text = message;
  toast.textAlignment = NSTextAlignmentCenter;
  toast.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.9];
  toast.textColor = [UIColor whiteColor];
  toast.font = [UIFont boldSystemFontOfSize:16];
  toast.layer.cornerRadius = 12;
  toast.clipsToBounds = YES;
  toast.alpha = 0;
  [self.view addSubview:toast];

  [UIView animateWithDuration:0.3
      animations:^{
        toast.alpha = 1;
      }
      completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3
            delay:2.0
            options:0
            animations:^{
              toast.alpha = 0;
            }
            completion:^(BOOL finished) {
              [toast removeFromSuperview];
            }];
      }];
}

@end
