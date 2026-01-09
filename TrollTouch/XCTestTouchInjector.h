#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface XCTestTouchInjector : NSObject

+ (instancetype)sharedInjector;

- (BOOL)initialize;

- (void)tapAtNormalizedPoint:(CGPoint)point;

- (void)swipeFromNormalizedPoint:(CGPoint)start
                              to:(CGPoint)end
                        duration:(NSTimeInterval)duration;

- (void)launchApp:(NSString *)bundleIdentifier;

@end

NS_ASSUME_NONNULL_END
