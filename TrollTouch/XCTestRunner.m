//
//  XCTestRunner.m
//  TrollTouch
//
//  Run XCTest without Xcode - directly from TrollStore app
//

#import "XCTestRunner.h"
#import <dlfcn.h>
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

    // Get test class using runtime
    Class testClass = NSClassFromString(@"TrollTouchUITests");
    if (!testClass) {
      NSLog(@"[XCTestRunner] ❌ Failed to find test class");
      _isRunning = NO;
      return;
    }

    NSLog(@"[XCTestRunner] ✅ Found test class: %@", testClass);

    // Get XCTestSuite class dynamically
    Class suiteClass = NSClassFromString(@"XCTestSuite");
    if (!suiteClass) {
      NSLog(@"[XCTestRunner] ❌ Failed to find XCTestSuite class");
      _isRunning = NO;
      return;
    }

    // Create test suite using runtime
    SEL suiteSelector = NSSelectorFromString(@"testSuiteForTestCaseClass:");
    if (![suiteClass respondsToSelector:suiteSelector]) {
      NSLog(@"[XCTestRunner] ❌ XCTestSuite doesn't respond to "
            @"testSuiteForTestCaseClass:");
      _isRunning = NO;
      return;
    }

// Invoke the method to get test suite
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    id suite = [suiteClass performSelector:suiteSelector withObject:testClass];
#pragma clang diagnostic pop

    if (!suite) {
      NSLog(@"[XCTestRunner] ❌ Failed to create test suite");
      _isRunning = NO;
      return;
    }

    NSLog(@"[XCTestRunner] ✅ Created test suite");

    // Run the test
    @try {
      NSLog(@"[XCTestRunner] 🚀 Starting test execution...");

      // Simply call the run method on the suite
      SEL runSelector = NSSelectorFromString(@"run");
      if ([suite respondsToSelector:runSelector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [suite performSelector:runSelector];
#pragma clang diagnostic pop

        NSLog(@"[XCTestRunner] ✅ Test execution completed");
      } else {
        NSLog(@"[XCTestRunner] ❌ Suite doesn't respond to run");
      }
    } @catch (NSException *exception) {
      NSLog(@"[XCTestRunner] ❌ Exception during test: %@", exception);
    } @finally {
      _isRunning = NO;
      NSLog(@"[XCTestRunner] Test runner stopped");
    }
  }
}

@end
