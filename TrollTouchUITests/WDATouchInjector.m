//
//  WDATouchInjector.m
//  Minimal WebDriverAgent-style touch injector
//

#import "WDATouchInjector.h"
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
    NSLog(@"[WDATouchInjector] ✅ Initialized (minimal version)");
  }
  return self;
}

#pragma mark - Touch Injection (Minimal Implementation)

- (void)tapAtNormalizedPoint:(CGPoint)point
                  completion:(void (^)(NSError *_Nullable))completion {
  NSLog(@"[WDATouchInjector] 👆 Tap at (%.3f, %.3f) - NOT IMPLEMENTED YET",
        point.x, point.y);

  // TODO: Implement actual touch injection
  // For now, just call completion
  if (completion) {
    completion(nil);
  }
}

- (void)swipeFromNormalizedPoint:(CGPoint)start
                              to:(CGPoint)end
                        duration:(NSTimeInterval)duration
                      completion:(void (^)(NSError *_Nullable))completion {
  NSLog(@"[WDATouchInjector] 👉 Swipe from (%.3f, %.3f) to (%.3f, %.3f) - NOT "
        @"IMPLEMENTED YET",
        start.x, start.y, end.x, end.y);

  // TODO: Implement actual swipe
  // For now, just call completion
  if (completion) {
    completion(nil);
  }
}

- (void)launchApp:(NSString *)bundleId
       completion:(void (^)(NSError *_Nullable))completion {
  NSLog(@"[WDATouchInjector] 🚀 Launch app: %@ - NOT IMPLEMENTED YET",
        bundleId);

  // TODO: Implement app launch
  // For now, just call completion
  if (completion) {
    completion(nil);
  }
}

@end
