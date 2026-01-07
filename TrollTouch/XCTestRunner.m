//
//  XCTestRunner.m
//  TrollTouch
//
//  Programmatic XCTest runner - runs tests without Xcode
//

#import "XCTestRunner.h"
#import <XCTest/XCTest.h>
#import <objc/runtime.h>

@implementation XCTestRunner

+ (void)runTestsInBackground {
  dispatch_async(
      dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"[XCTestRunner] 开始加载测试...");

        // 等待应用完全启动
        sleep(2);

        // 尝试加载测试 Bundle
        NSString *testBundlePath = [[NSBundle mainBundle].bundlePath
            stringByAppendingPathComponent:@"PlugIns/TrollTouchUITests.xctest"];

        NSBundle *testBundle = [NSBundle bundleWithPath:testBundlePath];

        if (!testBundle) {
          NSLog(@"[XCTestRunner] 错误: 找不到测试 Bundle");
          NSLog(@"[XCTestRunner] 路径: %@", testBundlePath);
          return;
        }

        NSError *error = nil;
        if (![testBundle loadAndReturnError:&error]) {
          NSLog(@"[XCTestRunner] 错误: 无法加载测试 Bundle: %@", error);
          return;
        }

        NSLog(@"[XCTestRunner] 测试 Bundle 加载成功");

        // 获取测试类
        Class testClass = NSClassFromString(@"TrollTouchUITests");
        if (!testClass) {
          NSLog(@"[XCTestRunner] 错误: 找不到测试类 TrollTouchUITests");
          return;
        }

        NSLog(@"[XCTestRunner] 找到测试类: %@", testClass);

        // 创建测试实例
        XCTestCase *testCase = [[testClass alloc]
            initWithSelector:@selector(testTikTokAutomation)];

        if (!testCase) {
          NSLog(@"[XCTestRunner] 错误: 无法创建测试实例");
          return;
        }

        NSLog(@"[XCTestRunner] 开始运行测试: testTikTokAutomation");

        // 运行测试
        @try {
          [testCase invokeTest];
          NSLog(@"[XCTestRunner] 测试完成");
        } @catch (NSException *exception) {
          NSLog(@"[XCTestRunner] 测试异常: %@", exception);
        }
      });
}

@end
