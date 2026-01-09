//
//  TrollTouchUITests.m
//  TrollTouch UI Tests
//
//  Bridge to AutomationManager
//

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
  NSLog(@"[TrollTouchUITests] Bridging to AutomationManager (Runtime)...");

  // Get class using runtime (it is hosted in the Main App executable)
  Class managerClass = NSClassFromString(@"AutomationManager");
  if (!managerClass) {
    NSLog(@"[TrollTouchUITests] ❌ Critical: AutomationManager class not found "
          @"in host app!");
    return;
  }

  // Get shared instance: [AutomationManager sharedManager]
  SEL sharedSel = NSSelectorFromString(@"sharedManager");
  if (![managerClass respondsToSelector:sharedSel]) {
    NSLog(@"[TrollTouchUITests] ❌ sharedManager selector not found");
    return;
  }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
  id manager = [managerClass performSelector:sharedSel];
#pragma clang diagnostic pop

  if (!manager) {
    NSLog(@"[TrollTouchUITests] ❌ Failed to get sharedManager instance");
    return;
  }

  // Call: [manager automationLoop]
  SEL loopSel = NSSelectorFromString(@"automationLoop");
  if (![manager respondsToSelector:loopSel]) {
    NSLog(@"[TrollTouchUITests] ❌ automationLoop selector not found");
    return;
  }

  NSLog(@"[TrollTouchUITests] Entering automation loop...");

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
  [manager performSelector:loopSel];
#pragma clang diagnostic pop

  NSLog(@"[TrollTouchUITests] Automation loop finished.");
}

@end
