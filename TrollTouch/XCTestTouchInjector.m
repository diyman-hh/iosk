#import "XCTestTouchInjector.h"
#import <dlfcn.h>
#import <objc/runtime.h>

// XCTest Private API
@interface XCUIApplication : NSObject
- (instancetype)initWithBundleIdentifier:(NSString *)bundleIdentifier;
- (void)launch;
- (void)terminate;
- (BOOL)waitForExistenceWithTimeout:(NSTimeInterval)timeout;
@end

@interface XCUICoordinate : NSObject
@end

@interface XCUIElement : NSObject
- (void)tap;
- (void)swipeUp;
- (void)swipeDown;
- (void)swipeLeft;
- (void)swipeRight;
- (void)pressForDuration:(NSTimeInterval)duration;
- (XCUICoordinate *)coordinateWithNormalizedOffset:(CGVector)normalizedOffset;
@end

@interface XCUICoordinate ()
- (void)tap;
- (void)pressForDuration:(NSTimeInterval)duration;
- (void)pressForDuration:(NSTimeInterval)duration
    thenDragToCoordinate:(XCUICoordinate *)otherCoordinate;
@end

@interface XCUIApplication (Elements)
@property(readonly) XCUIElement *firstMatch;
@end

@implementation XCTestTouchInjector {
  void *_xcTestHandle;
  XCUIApplication *_currentApp;
}

+ (instancetype)sharedInjector {
  static XCTestTouchInjector *shared = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    shared = [[XCTestTouchInjector alloc] init];
  });
  return shared;
}

- (BOOL)initialize {
  // Load XCTest framework
  _xcTestHandle = dlopen(
      "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/"
      "Developer/Library/Frameworks/XCTest.framework/XCTest",
      RTLD_LAZY);

  if (!_xcTestHandle) {
    // Try alternative path for device
    _xcTestHandle = dlopen(
        "/Developer/Library/Frameworks/XCTest.framework/XCTest", RTLD_LAZY);
  }

  if (!_xcTestHandle) {
    NSLog(@"[XCTestInjector] ❌ Failed to load XCTest framework");
    return NO;
  }

  NSLog(@"[XCTestInjector] ✅ XCTest framework loaded");
  return YES;
}

- (void)launchApp:(NSString *)bundleIdentifier {
  if (!_xcTestHandle) {
    NSLog(@"[XCTestInjector] ❌ XCTest not initialized");
    return;
  }

  Class XCUIApplicationClass = NSClassFromString(@"XCUIApplication");
  if (!XCUIApplicationClass) {
    NSLog(@"[XCTestInjector] ❌ XCUIApplication class not found");
    return;
  }

  _currentApp =
      [[XCUIApplicationClass alloc] initWithBundleIdentifier:bundleIdentifier];

  if (_currentApp) {
    NSLog(@"[XCTestInjector] 🚀 Launching %@...", bundleIdentifier);
    [_currentApp launch];

    // Wait for app to exist
    if ([_currentApp
            respondsToSelector:@selector(waitForExistenceWithTimeout:)]) {
      BOOL exists = [_currentApp waitForExistenceWithTimeout:5.0];
      NSLog(@"[XCTestInjector] App exists: %d", exists);
    }
  }
}

- (void)tapAtNormalizedPoint:(CGPoint)point {
  if (!_currentApp) {
    NSLog(@"[XCTestInjector] ❌ No app launched");
    return;
  }

  XCUIElement *element = [_currentApp firstMatch];
  if (!element) {
    NSLog(@"[XCTestInjector] ❌ No element found");
    return;
  }

  XCUICoordinate *coord =
      [element coordinateWithNormalizedOffset:CGVectorMake(point.x, point.y)];

  NSLog(@"[XCTestInjector] 👆 Tapping at (%.3f, %.3f)", point.x, point.y);
  [coord tap];
}

- (void)swipeFromNormalizedPoint:(CGPoint)start
                              to:(CGPoint)end
                        duration:(NSTimeInterval)duration {
  if (!_currentApp) {
    NSLog(@"[XCTestInjector] ❌ No app launched");
    return;
  }

  XCUIElement *element = [_currentApp firstMatch];
  if (!element) {
    NSLog(@"[XCTestInjector] ❌ No element found");
    return;
  }

  XCUICoordinate *startCoord =
      [element coordinateWithNormalizedOffset:CGVectorMake(start.x, start.y)];
  XCUICoordinate *endCoord =
      [element coordinateWithNormalizedOffset:CGVectorMake(end.x, end.y)];

  NSLog(@"[XCTestInjector] 👉 Swiping from (%.3f, %.3f) to (%.3f, %.3f)",
        start.x, start.y, end.x, end.y);

  [startCoord pressForDuration:0.01 thenDragToCoordinate:endCoord];
}

- (void)dealloc {
  if (_xcTestHandle) {
    dlclose(_xcTestHandle);
  }
}

@end
