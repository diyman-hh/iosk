//
//  WDATouchInjector.m
//  WebDriverAgent-style touch injector implementation
//

#import "WDATouchInjector.h"
#import "XCPointerEventPath.h"
#import <XCTest/XCTest.h>

@implementation WDATouchInjector

+ (instancetype)sharedInjector {
  static WDATouchInjector *shared = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    shared = [[WDATouchInjector alloc] init];
  });
  return shared;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    NSLog(@"[WDATouchInjector] ✅ Initialized with XCPointerEventPath support");
  }
  return self;
}

#pragma mark - Coordinate Conversion

- (CGPoint)screenPointFromNormalized:(CGPoint)normalizedPoint {
  // iPhone 7 screen dimensions: 750x1334 (logical) or 1334x750 (physical
  // pixels, @2x) Using logical pixel dimensions for XCTest
  CGFloat screenWidth = 750.0;
  CGFloat screenHeight = 1334.0;

  // Convert normalized (0.0-1.0) to actual screen coordinates
  CGFloat x = normalizedPoint.x * screenWidth;
  CGFloat y = normalizedPoint.y * screenHeight;

  return CGPointMake(x, y);
}

#pragma mark - Touch Injection

- (void)tapAtNormalizedPoint:(CGPoint)point
                  completion:(void (^)(NSError *_Nullable))completion {
  NSLog(@"[WDATouchInjector] 👆 Tap at normalized (%.3f, %.3f)", point.x,
        point.y);

  // Convert to screen coordinates
  CGPoint screenPoint = [self screenPointFromNormalized:point];
  NSLog(@"[WDATouchInjector] 📍 Screen coordinates: (%.1f, %.1f)",
        screenPoint.x, screenPoint.y);

  // Create touch event path
  XCPointerEventPath *path =
      [[XCPointerEventPath alloc] initForTouchAtPoint:screenPoint offset:0.0];

  // Lift up after 50ms
  [path liftUpAtOffset:0.05];

  // Create event record (orientation: 1 = Portrait)
  XCSynthesizedEventRecord *record = [[XCSynthesizedEventRecord alloc]
              initWithName:@"Tap"
      interfaceOrientation:1]; // UIInterfaceOrientationPortrait = 1
  [record addPointerEventPath:path];

  // Execute
  [[XCUIDevice sharedDevice]
      synthesizeEvent:record
           completion:^(NSError *_Nullable error) {
             if (error) {
               NSLog(@"[WDATouchInjector] ❌ Tap failed: %@",
                     error.localizedDescription);
             } else {
               NSLog(@"[WDATouchInjector] ✅ Tap succeeded");
             }
             if (completion) {
               completion(error);
             }
           }];
}

- (void)swipeFromNormalizedPoint:(CGPoint)start
                              to:(CGPoint)end
                        duration:(NSTimeInterval)duration
                      completion:(void (^)(NSError *_Nullable))completion {
  NSLog(@"[WDATouchInjector] 👉 Swipe from (%.3f, %.3f) to (%.3f, %.3f) "
        @"duration: %.2fs",
        start.x, start.y, end.x, end.y, duration);

  // Convert to screen coordinates
  CGPoint startScreen = [self screenPointFromNormalized:start];
  CGPoint endScreen = [self screenPointFromNormalized:end];

  NSLog(@"[WDATouchInjector] 📍 Screen: (%.1f, %.1f) → (%.1f, %.1f)",
        startScreen.x, startScreen.y, endScreen.x, endScreen.y);

  // Create touch event path
  XCPointerEventPath *path =
      [[XCPointerEventPath alloc] initForTouchAtPoint:startScreen offset:0.0];

  // Move to end point
  [path moveToPoint:endScreen atOffset:duration];

  // Lift up
  [path liftUpAtOffset:duration + 0.01];

  // Create event record (orientation: 1 = Portrait)
  XCSynthesizedEventRecord *record = [[XCSynthesizedEventRecord alloc]
              initWithName:@"Swipe"
      interfaceOrientation:1]; // UIInterfaceOrientationPortrait = 1
  [record addPointerEventPath:path];

  // Execute
  [[XCUIDevice sharedDevice]
      synthesizeEvent:record
           completion:^(NSError *_Nullable error) {
             if (error) {
               NSLog(@"[WDATouchInjector] ❌ Swipe failed: %@",
                     error.localizedDescription);
             } else {
               NSLog(@"[WDATouchInjector] ✅ Swipe succeeded");
             }
             if (completion) {
               completion(error);
             }
           }];
}

- (void)launchApp:(NSString *)bundleId
       completion:(void (^)(NSError *_Nullable))completion {
  NSLog(@"[WDATouchInjector] 🚀 Launching app: %@", bundleId);

  // Use XCUIApplication to launch the app
  XCUIApplication *app =
      [[XCUIApplication alloc] initWithBundleIdentifier:bundleId];
  [app launch];

  // Wait a bit for app to launch
  dispatch_after(
      dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)),
      dispatch_get_main_queue(), ^{
        BOOL exists = app.exists;
        NSLog(@"[WDATouchInjector] App exists: %d", exists);

        if (exists) {
          NSLog(@"[WDATouchInjector] ✅ App launched successfully");
          if (completion)
            completion(nil);
        } else {
          NSError *error = [NSError
              errorWithDomain:@"WDATouchInjector"
                         code:-1
                     userInfo:@{
                       NSLocalizedDescriptionKey : @"App failed to launch"
                     }];
          NSLog(@"[WDATouchInjector] ❌ App launch failed");
          if (completion)
            completion(error);
        }
      });
}

@end
