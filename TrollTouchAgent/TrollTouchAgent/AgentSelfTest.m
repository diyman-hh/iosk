//
//  AgentSelfTest.m
//  TrollTouchAgent
//
//  Self-test for Agent APIs
//

#import "AgentSelfTest.h"
#import "FileLogger.h"
#import "SharedCommandQueue.h"
#import "TouchInjector.h"
#import <UIKit/UIKit.h>


@implementation AgentSelfTest

+ (void)runAllTests {
  FileLogger *logger = [FileLogger sharedLogger];

  [logger log:@""];
  [logger log:@"========================================"];
  [logger log:@"🧪 AGENT SELF-TEST STARTING"];
  [logger log:@"========================================"];
  [logger log:@""];

  [self testTouchInjector];
  [self testSharedCommandQueue];
  [self testScreenInfo];

  [logger log:@""];
  [logger log:@"========================================"];
  [logger log:@"✅ AGENT SELF-TEST COMPLETE"];
  [logger log:@"========================================"];
  [logger
      log:[NSString stringWithFormat:@"📁 Log file: %@", [logger getLogPath]]];
  [logger log:@""];
}

+ (void)testTouchInjector {
  FileLogger *logger = [FileLogger sharedLogger];

  [logger log:@""];
  [logger log:@"--- Test 1: TouchInjector ---"];

  TouchInjector *injector = [TouchInjector sharedInjector];
  if (!injector) {
    [logger log:@"❌ FAILED: TouchInjector is nil"];
    return;
  }
  [logger log:@"✅ TouchInjector instance created"];

  // Test current method
  NSString *method = [injector currentMethod];
  [logger log:[NSString stringWithFormat:@"📋 Current injection method: %@",
                                         method ?: @"NONE"]];

  // Test tap (center of screen)
  [logger log:@"🧪 Testing tap at (0.5, 0.5)..."];
  BOOL tapResult = [injector tapAtPoint:CGPointMake(0.5, 0.5)];
  [logger log:[NSString stringWithFormat:@"%@ Tap result: %@",
                                         tapResult ? @"✅" : @"❌",
                                         tapResult ? @"SUCCESS" : @"FAILED"]];

  // Test swipe
  [logger log:@"🧪 Testing swipe from (0.3, 0.3) to (0.7, 0.7)..."];
  BOOL swipeResult = [injector swipeFrom:CGPointMake(0.3, 0.3)
                                      to:CGPointMake(0.7, 0.7)
                                duration:0.3];
  [logger log:[NSString stringWithFormat:@"%@ Swipe result: %@",
                                         swipeResult ? @"✅" : @"❌",
                                         swipeResult ? @"SUCCESS" : @"FAILED"]];
}

+ (void)testSharedCommandQueue {
  FileLogger *logger = [FileLogger sharedLogger];

  [logger log:@""];
  [logger log:@"--- Test 2: SharedCommandQueue ---"];

  SharedCommandQueue *queue = [SharedCommandQueue sharedQueue];
  if (!queue) {
    [logger log:@"❌ FAILED: SharedCommandQueue is nil"];
    return;
  }
  [logger log:@"✅ SharedCommandQueue instance created"];

  // Test sending a response
  [logger log:@"🧪 Testing sendResponse..."];
  NSDictionary *testResponse =
      @{@"commandId" : @"test-123", @"success" : @YES, @"error" : @""};
  [queue sendResponse:testResponse];
  [logger log:@"✅ Response sent (check if it crashes)"];

  // Test App Groups access
  [logger log:@"🧪 Testing App Groups access..."];
  NSUserDefaults *shared =
      [[NSUserDefaults alloc] initWithSuiteName:@"group.com.trolltouch.shared"];
  if (shared) {
    [shared setObject:@"test-value" forKey:@"test-key"];
    BOOL synced = [shared synchronize];
    NSString *readBack = [shared objectForKey:@"test-key"];

    if (synced && [readBack isEqualToString:@"test-value"]) {
      [logger log:@"✅ App Groups read/write SUCCESS"];
    } else {
      [logger log:[NSString stringWithFormat:@"❌ App Groups read/write FAILED "
                                             @"(synced=%d, readBack=%@)",
                                             synced, readBack]];
    }

    [shared removeObjectForKey:@"test-key"];
    [shared synchronize];
  } else {
    [logger log:@"❌ FAILED: Cannot access App Groups"];
  }
}

+ (void)testScreenInfo {
  FileLogger *logger = [FileLogger sharedLogger];

  [logger log:@""];
  [logger log:@"--- Test 3: Screen Information ---"];

  CGRect screenBounds = [[UIScreen mainScreen] bounds];
  CGFloat scale = [[UIScreen mainScreen] scale];

  [logger log:[NSString stringWithFormat:@"📱 Screen bounds: %.0f x %.0f",
                                         screenBounds.size.width,
                                         screenBounds.size.height]];
  [logger log:[NSString stringWithFormat:@"📱 Screen scale: %.1fx", scale]];
  [logger log:[NSString stringWithFormat:@"📱 Actual pixels: %.0f x %.0f",
                                         screenBounds.size.width * scale,
                                         screenBounds.size.height * scale]];

  // Test coordinate conversion
  CGPoint normalized = CGPointMake(0.5, 0.5);
  CGFloat pixelX = normalized.x * screenBounds.size.width;
  CGFloat pixelY = normalized.y * screenBounds.size.height;
  [logger
      log:[NSString
              stringWithFormat:@"🧪 Normalized (0.5, 0.5) → Pixel (%.1f, %.1f)",
                               pixelX, pixelY]];
}

@end
