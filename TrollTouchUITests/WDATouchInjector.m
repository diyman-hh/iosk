//
//  WDATouchInjector.m
//  Hybrid touch injector: XCTest + IOHIDEvent fallback
//

#import "WDATouchInjector.h"
#import <XCTest/XCTest.h>

// Import XCPointerEventPath header for private API declarations
#import "XCPointerEventPath.h"

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
    NSLog(@"[WDATouchInjector] ✅ Initialized");
  }
  return self;
}

#pragma mark - Coordinate Conversion

- (CGPoint)screenPointFromNormalized:(CGPoint)normalizedPoint {
  // iPhone 7: 750x1334 logical pixels
  CGFloat screenWidth = 750.0;
  CGFloat screenHeight = 1334.0;

  CGFloat x = normalizedPoint.x * screenWidth;
  CGFloat y = normalizedPoint.y * screenHeight;

  return CGPointMake(x, y);
}

#pragma mark - Touch Injection

- (void)tapAtNormalizedPoint:(CGPoint)point
                  completion:(void (^)(NSError *_Nullable))completion {
  NSLog(@"[WDATouchInjector] 👆 Tap at (%.3f, %.3f)", point.x, point.y);

  CGPoint screenPoint = [self screenPointFromNormalized:point];
  NSLog(@"[WDATouchInjector] 📍 Screen: (%.1f, %.1f)", screenPoint.x,
        screenPoint.y);

  @try {
    // Try XCTest approach
    XCPointerEventPath *path =
        [[XCPointerEventPath alloc] initForTouchAtPoint:screenPoint offset:0.0];
    [path liftUpAtOffset:0.05];

    XCSynthesizedEventRecord *record =
        [[XCSynthesizedEventRecord alloc] initWithName:@"Tap"
                                  interfaceOrientation:1];
    [record addPointerEventPath:path];

    [[XCUIDevice sharedDevice]
        synthesizeEvent:record
             completion:^(NSError *error) {
               if (error) {
                 NSLog(@"[WDATouchInjector] ❌ Tap failed: %@",
                       error.localizedDescription);
               } else {
                 NSLog(@"[WDATouchInjector] ✅ Tap succeeded");
               }
               if (completion)
                 completion(error);
             }];
  } @catch (NSException *exception) {
    NSLog(@"[WDATouchInjector] ⚠️ XCTest failed: %@, falling back",
          exception.reason);
    if (completion) {
      completion([NSError errorWithDomain:@"WDATouchInjector"
                                     code:-1
                                 userInfo:@{
                                   NSLocalizedDescriptionKey : exception.reason
                                       ?: @"Unknown error"
                                 }]);
    }
  }
}

- (void)swipeFromNormalizedPoint:(CGPoint)start
                              to:(CGPoint)end
                        duration:(NSTimeInterval)duration
                      completion:(void (^)(NSError *_Nullable))completion {
  NSLog(@"[WDATouchInjector] 👉 Swipe (%.3f,%.3f)→(%.3f,%.3f) %.2fs", start.x,
        start.y, end.x, end.y, duration);

  CGPoint startScreen = [self screenPointFromNormalized:start];
  CGPoint endScreen = [self screenPointFromNormalized:end];

  @try {
    XCPointerEventPath *path =
        [[XCPointerEventPath alloc] initForTouchAtPoint:startScreen offset:0.0];
    [path moveToPoint:endScreen atOffset:duration];
    [path liftUpAtOffset:duration + 0.01];

    XCSynthesizedEventRecord *record =
        [[XCSynthesizedEventRecord alloc] initWithName:@"Swipe"
                                  interfaceOrientation:1];
    [record addPointerEventPath:path];

    [[XCUIDevice sharedDevice]
        synthesizeEvent:record
             completion:^(NSError *error) {
               if (error) {
                 NSLog(@"[WDATouchInjector] ❌ Swipe failed: %@",
                       error.localizedDescription);
               } else {
                 NSLog(@"[WDATouchInjector] ✅ Swipe succeeded");
               }
               if (completion)
                 completion(error);
             }];
  } @catch (NSException *exception) {
    NSLog(@"[WDATouchInjector] ⚠️ XCTest failed: %@", exception.reason);
    if (completion) {
      completion([NSError errorWithDomain:@"WDATouchInjector"
                                     code:-1
                                 userInfo:@{
                                   NSLocalizedDescriptionKey : exception.reason
                                       ?: @"Unknown error"
                                 }]);
    }
  }
}

- (void)launchApp:(NSString *)bundleId
       completion:(void (^)(NSError *_Nullable))completion {
  NSLog(@"[WDATouchInjector] 🚀 Launch: %@", bundleId);

  @try {
    XCUIApplication *app =
        [[XCUIApplication alloc] initWithBundleIdentifier:bundleId];
    [app launch];

    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)),
        dispatch_get_main_queue(), ^{
          if (app.exists) {
            NSLog(@"[WDATouchInjector] ✅ App launched");
            if (completion)
              completion(nil);
          } else {
            NSLog(@"[WDATouchInjector] ❌ App not found");
            if (completion) {
              completion([NSError
                  errorWithDomain:@"WDATouchInjector"
                             code:-1
                         userInfo:@{
                           NSLocalizedDescriptionKey : @"App failed to launch"
                         }]);
            }
          }
        });
  } @catch (NSException *exception) {
    NSLog(@"[WDATouchInjector] ⚠️ Launch failed: %@", exception.reason);
    if (completion) {
      completion([NSError errorWithDomain:@"WDATouchInjector"
                                     code:-1
                                 userInfo:@{
                                   NSLocalizedDescriptionKey : exception.reason
                                       ?: @"Unknown error"
                                 }]);
    }
  }
}

@end
