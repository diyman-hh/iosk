//
//  RootViewController.m
//  TrollTouch (Simplified for XCTest)
//

#import "RootViewController.h"

@implementation RootViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  self.view.backgroundColor = [UIColor whiteColor];

  // Title
  UILabel *titleLabel =
      [[UILabel alloc] initWithFrame:CGRectMake(20, 100, 335, 40)];
  titleLabel.text = @"TrollTouch XCTest";
  titleLabel.font = [UIFont boldSystemFontOfSize:24];
  titleLabel.textAlignment = NSTextAlignmentCenter;
  [self.view addSubview:titleLabel];

  // Instructions
  UITextView *instructions =
      [[UITextView alloc] initWithFrame:CGRectMake(20, 160, 335, 400)];
  instructions.editable = NO;
  instructions.font = [UIFont systemFontOfSize:14];
  instructions.text = @"TrollTouch 现在使用 XCTest 框架运行。\n\n"
                      @"运行方法：\n\n"
                      @"1. 通过 Xcode 运行测试：\n"
                      @"   - 打开项目\n"
                      @"   - Product > Test\n"
                      @"   - 或按 Cmd+U\n\n"
                      @"2. 通过命令行运行：\n"
                      @"   xcodebuild test \\\n"
                      @"     -scheme TrollTouch \\\n"
                      @"     -destination 'platform=iOS,id=<UDID>'\n\n"
                      @"3. 运行特定测试：\n"
                      @"   - testTikTokAutomation (完整自动化)\n"
                      @"   - testSingleLike (测试点赞)\n"
                      @"   - testSingleSwipe (测试滑动)\n\n"
                      @"优势：\n"
                      @"✅ 真正的后台运行\n"
                      @"✅ 跨应用控制\n"
                      @"✅ 官方 API 支持\n"
                      @"✅ 稳定可靠";
  [self.view addSubview:instructions];
}

@end
