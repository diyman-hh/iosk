//
//  AgentSelfTest.m
//  TrollTouchAgent
//
//  Self-test for Agent APIs
//

#import "AgentSelfTest.h"
#import "SharedCommandQueue.h"
#import "TouchInjector.h"
#import <UIKit/UIKit.h>


@implementation AgentSelfTest

+ (void)runAllTests {
  NSLog(@"");
  NSLog(@"========================================");
  NSLog(@"🧪 AGENT SELF-TEST STARTING");
  NSLog(@"========================================");
  NSLog(@"");

  [self testTouchInjector];
  [self testSharedCommandQueue];
  [self testScreenInfo];

  NSLog(@"");
  NSLog(@"========================================");
  NSLog(@"✅ AGENT SELF-TEST COMPLETE");
  NSLog(@"========================================");
  NSLog(@"");
}

+ (void)testTouchInjector {
  NSLog(@"");
  NSLog(@"--- Test 1: TouchInjector ---");

  TouchInjector *injector = [TouchInjector sharedInjector];
  if (!injector) {
    NSLog(@"❌ FAILED: TouchInjector is nil");
    return;
  }
  NSLog(@"✅ TouchInjector instance created");

  // Test current method
  NSString *method = [injector currentMethod];
  NSLog(@"📋 Current injection method: %@", method ?: @"NONE");

  // Test tap (center of screen)
  NSLog(@"🧪 Testing tap at (0.5, 0.5)...");
  BOOL tapResult = [injector tapAtPoint:CGPointMake(0.5, 0.5)];
  NSLog(@"%@ Tap result: %@", tapResult ? @"✅" : @"❌",
        tapResult ? @"SUCCESS" : @"FAILED");

  // Test swipe
  NSLog(@"🧪 Testing swipe from (0.3, 0.3) to (0.7, 0.7)...");
  BOOL swipeResult = [injector swipeFrom:CGPointMake(0.3, 0.3)
                                      to:CGPointMake(0.7, 0.7)
                                duration:0.3];
  NSLog(@"%@ Swipe result: %@", swipeResult ? @"✅" : @"❌",
        swipeResult ? @"SUCCESS" : @"FAILED");
}

+ (void)testSharedCommandQueue {
  NSLog(@"");
  NSLog(@"--- Test 2: SharedCommandQueue ---");

  SharedCommandQueue *queue = [SharedCommandQueue sharedQueue];
  if (!queue) {
    NSLog(@"❌ FAILED: SharedCommandQueue is nil");
    return;
  }
  NSLog(@"✅ SharedCommandQueue instance created");

  // Test sending a response
  NSLog(@"🧪 Testing sendResponse...");
  NSDictionary *testResponse =
      @{@"commandId" : @"test-123", @"success" : @YES, @"error" : @""};
  [queue sendResponse:testResponse];
  NSLog(@"✅ Response sent (check if it crashes)");

  // Test App Groups access
  NSLog(@"🧪 Testing App Groups access...");
  NSUserDefaults *shared =
      [[NSUserDefaults alloc] initWithSuiteName:@"group.com.trolltouch.shared"];
  if (shared) {
    [shared setObject:@"test-value" forKey:@"test-key"];
    BOOL synced = [shared synchronize];
    NSString *readBack = [shared objectForKey:@"test-key"];

    if (synced && [readBack isEqualToString:@"test-value"]) {
      NSLog(@"✅ App Groups read/write SUCCESS");
    } else {
      NSLog(@"❌ App Groups read/write FAILED (synced=%d, readBack=%@)", synced,
            readBack);
    }

    [shared removeObjectForKey:@"test-key"];
    [shared synchronize];
  } else {
    NSLog(@"❌ FAILED: Cannot access App Groups");
  }
}

+ (void)testScreenInfo {
  NSLog(@"");
  NSLog(@"--- Test 3: Screen Information ---");

  CGRect screenBounds = [[UIScreen mainScreen] bounds];
  CGFloat scale = [[UIScreen mainScreen] scale];

  NSLog(@"📱 Screen bounds: %.0f x %.0f", screenBounds.size.width,
        screenBounds.size.height);
  NSLog(@"📱 Screen scale: %.1fx", scale);
  NSLog(@"📱 Actual pixels: %.0f x %.0f", screenBounds.size.width * scale,
        screenBounds.size.height * scale);

  // Test coordinate conversion
  CGPoint normalized = CGPointMake(0.5, 0.5);
  CGFloat pixelX = normalized.x * screenBounds.size.width;
  CGFloat pixelY = normalized.y * screenBounds.size.height;
  NSLog(@"🧪 Normalized (0.5, 0.5) → Pixel (%.1f, %.1f)", pixelX, pixelY);
}

@end
