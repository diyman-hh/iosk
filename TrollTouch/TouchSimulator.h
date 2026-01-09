#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface TouchSimulator : NSObject

+ (instancetype)sharedSimulator;

/**
 * Simulate a tap at normalized coordinates (0.0 - 1.0)
 */
- (void)tapAtPoint:(CGPoint)point;

/**
 * Simulate a swipe
 */
- (void)swipeFrom:(CGPoint)start
               to:(CGPoint)end
         duration:(NSTimeInterval)duration;

@end
