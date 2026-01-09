//
//  TrollTouchUITests.m
//  TrollTouch UI Tests
//
//  Bridge to AutomationManager
//

#import "AutomationManager.h"
#import <XCTest/XCTest.h>


// Interface for XCTestCase to avoid import issues
@interface TrollTouchUITests : XCTestCase
@end

@implementation TrollTouchUITests

- (void)setUp {
  [super setUp];

  // Disable UI interruption monitoring
  self.continueAfterFailure = YES;

  // Redirect NSLog to AutomationManager log if available
  NSLog(@"[TrollTouchUITests] Test bundle loaded and setUp called.");
}

- (void)tearDown {
  [super tearDown];
}

/**
 * Main entry point called by XCTestRunner
 */
- (void)testAutomationBridge {
  NSLog(@"[TrollTouchUITests] Bridging to AutomationManager...");

  // Ensure AutomationManager is initialized
  AutomationManager *manager = [AutomationManager sharedManager];

  // Start the automation loop
  // This will block the test thread, which is exactly what we want
  // The loop runs until isRunning becomes NO
  [manager automationLoop];

  NSLog(@"[TrollTouchUITests] Automation loop finished.");
}

@end
