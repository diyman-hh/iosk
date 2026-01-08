//
//  XCTestRunner.m
//  TrollTouch
//
//  Run XCTest without Xcode - directly from TrollStore app
//

#import "XCTestRunner.h"
#import <XCTest/XCTest.h>
#import <objc/runtime.h>

static BOOL _isRunning = NO;
static NSThread *_testThread = nil;

@implementation XCTestRunner

+ (void)startAutomation {
  if (_isRunning) {
    NSLog(@"[XCTestRunner] Already running");
    return;
  }

  NSLog(@"[XCTestRunner] Starting automation...");
  _isRunning = YES;

  // Run in background thread
  _testThread = [[NSThread alloc] initWithTarget:self
                                        selector:@selector(runTestsInBackground)
                                          object:nil];
  [_testThread start];
}

+ (void)stopAutomation {
  NSLog(@"[XCTestRunner] Stopping automation...");
  _isRunning = NO;

  if (_testThread) {
    [_testThread cancel];
    _testThread = nil;
  }
}

+ (BOOL)isRunning {
  return _isRunning;
}

+ (void)runTestsInBackground {
  @autoreleasepool {
    NSLog(@"[XCTestRunner] Loading test bundle...");

    // Get test bundle path
    NSString *bundlePath = [[NSBundle mainBundle].bundlePath
        stringByAppendingPathComponent:@"PlugIns/TrollTouchUITests.xctest"];

    NSLog(@"[XCTestRunner] Bundle path: %@", bundlePath);

    // Load test bundle
    NSBundle *testBundle = [NSBundle bundleWithPath:bundlePath];
    if (!testBundle) {
      NSLog(@"[XCTestRunner] ❌ Failed to find test bundle");
      _isRunning = NO;
      return;
    }

    NSError *error = nil;
    if (![testBundle loadAndReturnError:&error]) {
      NSLog(@"[XCTestRunner] ❌ Failed to load test bundle: %@", error);
      _isRunning = NO;
      return;
    }

    NSLog(@"[XCTestRunner] ✅ Test bundle loaded");

    // Get test class
    Class testClass = NSClassFromString(@"TrollTouchUITests");
    if (!testClass) {
      NSLog(@"[XCTestRunner] ❌ Failed to find test class");
      _isRunning = NO;
      return;
    }

    NSLog(@"[XCTestRunner] ✅ Found test class: %@", testClass);

    // Create test suite
    XCTestSuite *suite = [XCTestSuite testSuiteForTestCaseClass:testClass];
    if (!suite) {
      NSLog(@"[XCTestRunner] ❌ Failed to create test suite");
      _isRunning = NO;
      return;
    }

    NSLog(@"[XCTestRunner] ✅ Created test suite with %lu tests",
          (unsigned long)suite.tests.count);

    // Run the main automation test
    @try {
      NSLog(@"[XCTestRunner] 🚀 Starting test execution...");

      // Create test run
      XCTestSuiteRun *run = [[XCTestSuiteRun alloc] initWithTest:suite];

      // Perform test
      [suite performTest:run];

      NSLog(@"[XCTestRunner] ✅ Test execution completed");
      NSLog(@"[XCTestRunner] Results: %lu tests, %lu failures",
            (unsigned long)run.testCaseCount,
            (unsigned long)run.totalFailureCount);
    } @catch (NSException *exception) {
      NSLog(@"[XCTestRunner] ❌ Exception during test: %@", exception);
    } @finally {
      _isRunning = NO;
      NSLog(@"[XCTestRunner] Test runner stopped");
    }
  }
}

@end
