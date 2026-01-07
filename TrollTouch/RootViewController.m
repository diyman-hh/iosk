//
//  RootViewController.m
//  TrollTouch (XCTest version with auto-start)
//

#import "RootViewController.h"
#import "XCTestRunner.h"

@implementation RootViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  self.view.backgroundColor = [UIColor colorWithRed:0.95
                                              green:0.95
                                               blue:0.97
                                              alpha:1.0];

  CGFloat w = self.view.bounds.size.width;
  CGFloat y = 80;

  // Title
  UILabel *titleLabel =
      [[UILabel alloc] initWithFrame:CGRectMake(20, y, w - 40, 50)];
  titleLabel.text = @"🤖 TrollTouch XCTest";
  titleLabel.font = [UIFont boldSystemFontOfSize:28];
  titleLabel.textAlignment = NSTextAlignmentCenter;
  [self.view addSubview:titleLabel];
  y += 70;

  // Start button
  UIButton *startButton = [UIButton buttonWithType:UIButtonTypeSystem];
  startButton.frame = CGRectMake(40, y, w - 80, 60);
  [startButton setTitle:@"🚀 启动自动化测试" forState:UIControlStateNormal];
  startButton.titleLabel.font = [UIFont boldSystemFontOfSize:20];
  startButton.backgroundColor = [UIColor colorWithRed:0.2
                                                green:0.8
                                                 blue:0.4
                                                alpha:1.0];
  [startButton setTitleColor:[UIColor whiteColor]
                    forState:UIControlStateNormal];
  startButton.layer.cornerRadius = 12;
  [startButton addTarget:self
                  action:@selector(startTests)
        forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:startButton];
  y += 80;

  // Instructions
  UITextView *instructions =
      [[UITextView alloc] initWithFrame:CGRectMake(20, y, w - 40, 400)];
  instructions.editable = NO;
  instructions.font = [UIFont systemFontOfSize:14];
  instructions.backgroundColor = [UIColor clearColor];
  instructions.text = @"📱 TrollTouch XCTest 版本\n\n"
                      @"✅ 真正的后台运行\n"
                      @"✅ 跨应用控制 TikTok\n"
                      @"✅ 使用官方 XCTest API\n"
                      @"✅ 稳定可靠\n\n"
                      @"使用方法：\n\n"
                      @"1. 点击上方 \"启动自动化测试\" 按钮\n"
                      @"2. 测试会在后台自动运行\n"
                      @"3. TikTok 会自动启动并开始刷视频\n"
                      @"4. 查看系统日志了解运行状态\n\n"
                      @"配置：\n"
                      @"• 总视频数: 100\n"
                      @"• 观看时长: 3-8秒\n"
                      @"• 点赞概率: 30%\n"
                      @"• 关注概率: 5%\n\n"
                      @"注意：\n"
                      @"⚠️ 确保 TikTok 已安装\n"
                      @"⚠️ 首次运行可能需要授权\n"
                      @"⚠️ 测试运行时可以最小化此应用";
  [self.view addSubview:instructions];
}

- (void)startTests {
  NSLog(@"[RootViewController] 用户点击启动测试");

  // 显示提示
  UIAlertController *alert = [UIAlertController
      alertControllerWithTitle:@"🚀 启动测试"
                       message:
                           @"自动化测试即将开始\n\nTikTok "
                           @"会自动启动\n你可以最小化此应用\n测试会在后台运行"
                preferredStyle:UIAlertControllerStyleAlert];

  [alert addAction:[UIAlertAction
                       actionWithTitle:@"开始"
                                 style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction *_Nonnull action) {
                                 // 启动测试
                                 [XCTestRunner runTestsInBackground];

                                 // 显示成功提示
                                 [self showToast:@"✅ 测试已启动，请查看日志"];
                               }]];

  [alert addAction:[UIAlertAction actionWithTitle:@"取消"
                                            style:UIAlertActionStyleCancel
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
