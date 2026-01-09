//
//  TrollTouchUITests.m
//  WebDriverAgent-style automation server
//

#import "AutomationServer.h"
#import "WDATouchInjector.h"
#import <XCTest/XCTest.h>


@interface TrollTouchUITests : XCTestCase
@end

@implementation TrollTouchUITests

- (void)setUp {
  [super setUp];
  self.continueAfterFailure = YES;

  NSLog(@"[TrollTouchUITests] ========================================");
  NSLog(@"[TrollTouchUITests] 🚀 WebDriverAgent-Style Automation Server");
  NSLog(@"[TrollTouchUITests] ========================================");

  // Start automation server
  [[AutomationServer sharedServer] startOnPort:8100];

  // Initialize touch injector
  [WDATouchInjector sharedInjector];

  NSLog(@"[TrollTouchUITests] ✅ Server initialized and ready");
}

- (void)tearDown {
  [[AutomationServer sharedServer] stop];
  [super tearDown];
}

/**
 * Main test that keeps the automation server running
 * This test never finishes - it keeps the UITests process alive
 */
- (void)testAutomationServer {
  NSLog(@"[TrollTouchUITests] 🔄 Automation server is running...");
  NSLog(@"[TrollTouchUITests] 📡 Waiting for commands from main app");

  // Keep the test running indefinitely
  // This allows the AutomationServer to receive and process commands
  while (YES) {
    // Run the run loop to process events
    [[NSRunLoop currentRunLoop]
           runMode:NSDefaultRunLoopMode
        beforeDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];

    // Check if server is still running
    if (![[AutomationServer sharedServer] isRunning]) {
      NSLog(@"[TrollTouchUITests] ⚠️ Server stopped, exiting...");
      break;
    }
  }

  NSLog(@"[TrollTouchUITests] Test finished");
}

@end
