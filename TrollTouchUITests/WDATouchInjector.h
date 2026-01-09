//
//  WDATouchInjector.h
//  WebDriverAgent-style touch injector
//

#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

@interface WDATouchInjector : NSObject

/// Shared instance
+ (instancetype)sharedInjector;

/// Tap at a normalized point (0.0-1.0)
/// @param point Normalized coordinates (x: 0.0-1.0, y: 0.0-1.0)
/// @param completion Completion handler with optional error
- (void)tapAtNormalizedPoint:(CGPoint)point
                  completion:
                      (void (^_Nullable)(NSError *_Nullable error))completion;

/// Swipe from one normalized point to another
/// @param start Start point (normalized 0.0-1.0)
/// @param end End point (normalized 0.0-1.0)
/// @param duration Duration of the swipe in seconds
/// @param completion Completion handler with optional error
- (void)swipeFromNormalizedPoint:(CGPoint)start
                              to:(CGPoint)end
                        duration:(NSTimeInterval)duration
                      completion:(void (^_Nullable)(NSError *_Nullable error))
                                     completion;

/// Launch an application by bundle identifier
/// @param bundleId Application bundle identifier (e.g.,
/// "com.zhiliaoapp.musically")
/// @param completion Completion handler with optional error
- (void)launchApp:(NSString *)bundleId
       completion:(void (^_Nullable)(NSError *_Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
