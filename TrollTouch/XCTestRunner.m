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

// Helper for UI logging
static void broadcastLog(NSString *format, ...) {
  va_list args;
  va_start(args, format);
  NSString *msg = [[NSString alloc] initWithFormat:format arguments:args];
  va_end(args);

  NSLog(@"%@", msg); // Keep console log
  [[NSNotificationCenter defaultCenter]
      postNotificationName:@"LogNotification"
                    object:[NSString stringWithFormat:@"[Runner] %@", msg]];
}

@implementation XCTestRunner

+ (void)startAutomation {
  if (_isRunning) {
    broadcastLog(@"⚠️ Already running");
    return;
  }

  broadcastLog(@"🚀 Starting automation...");
  _isRunning = YES;

  // Run in background thread
  _testThread = [[NSThread alloc] initWithTarget:self
                                        selector:@selector(runTestsInBackground)
                                          object:nil];
  [_testThread start];
}

+ (void)stopAutomation {
  broadcastLog(@"🛑 Stopping automation...");
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
    broadcastLog(@"Loading test bundle...");

    // Get test bundle path
    NSString *bundlePath = [[NSBundle mainBundle].bundlePath
        stringByAppendingPathComponent:@"PlugIns/TrollTouchUITests.xctest"];

    broadcastLog(@"Bundle path: %@", bundlePath);

    // Load test bundle
    NSBundle *testBundle = [NSBundle bundleWithPath:bundlePath];
    if (!testBundle) {
      broadcastLog(@"❌ Failed to find test bundle");
      _isRunning = NO;
      return;
    }

    NSError *error = nil;
    if (![testBundle loadAndReturnError:&error]) {
      broadcastLog(@"❌ Failed to load test bundle: %@", error);
      _isRunning = NO;
      return;
    }

    broadcastLog(@"✅ Test bundle loaded");

    // 🔧 验证XCTest框架是否已加载
    NSLog(@"[XCTestRunner] Verifying XCTest framework...");
    Class testCaseClass = NSClassFromString(@"XCTestCase");
    Class uiAppClass = NSClassFromString(@"XCUIApplication");
    Class uiCoordinateClass = NSClassFromString(@"XCUICoordinate");

    if (testCaseClass && uiAppClass && uiCoordinateClass) {
      NSLog(@"[XCTestRunner] ✅ XCTest framework IS loaded and ready");
      broadcastLog(@"   - XCTestCase: %@", testCaseClass);
      broadcastLog(@"   - XCUIApplication: %@", uiAppClass);
      broadcastLog(@"   - XCUICoordinate: %@", uiCoordinateClass);
    } else {
      NSLog(@"[XCTestRunner] ⚠️ XCTest framework NOT fully loaded:");
      NSLog(@"[XCTestRunner]    - XCTestCase: %@", testCaseClass ?: @"nil");
      NSLog(@"[XCTestRunner]    - XCUIApplication: %@", uiAppClass ?: @"nil");
      NSLog(@"[XCTestRunner]    - XCUICoordinate: %@",
            uiCoordinateClass ?: @"nil");
    }

    // Get test class using runtime
    Class testClass = NSClassFromString(@"TrollTouchUITests");
    if (!testClass) {
      broadcastLog(@"❌ Failed to find test class 'TrollTouchUITests'");
      _isRunning = NO;
      return;
    }

    broadcastLog(@"✅ Found test class: %@", testClass);

    // Get XCTestSuite class dynamically
    Class suiteClass = NSClassFromString(@"XCTestSuite");
    if (!suiteClass) {
      broadcastLog(@"❌ Failed to find XCTestSuite class");
      _isRunning = NO;
      return;
    }

    // Create test suite using runtime
    SEL suiteSelector = NSSelectorFromString(@"testSuiteForTestCaseClass:");
    if (![suiteClass respondsToSelector:suiteSelector]) {
      broadcastLog(
          @"❌ XCTestSuite doesn't respond to testSuiteForTestCaseClass:");
      _isRunning = NO;
      return;
    }

// Invoke the method to get test suite
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    id suite = [suiteClass performSelector:suiteSelector withObject:testClass];
#pragma clang diagnostic pop

    if (!suite) {
      broadcastLog(@"❌ Failed to create test suite");
      _isRunning = NO;
      return;
    }

    broadcastLog(@"✅ Created test suite");

    // Run the test
    @try {
      broadcastLog(@"🚀 Starting test execution via performSelector...");

      // Simply call the run method on the suite
      SEL runSelector = NSSelectorFromString(@"run");
      if ([suite respondsToSelector:runSelector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [suite performSelector:runSelector];
#pragma clang diagnostic pop

        broadcastLog(@"✅ Test execution completed");
      } else {
        broadcastLog(@"❌ Suite doesn't respond to run selector");
      }
    } @catch (NSException *exception) {
      broadcastLog(@"❌ Exception during test: %@", exception);
    } @finally {
      _isRunning = NO;
      broadcastLog(@"Test runner stopped");
    }
  }
}

@end
