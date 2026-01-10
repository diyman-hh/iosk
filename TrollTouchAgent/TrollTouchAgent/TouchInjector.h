//
//  TouchInjector.h
//  TrollTouchAgent
//

#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>


@interface TouchInjector : NSObject

+ (instancetype)sharedInjector;

// 触摸注入方法
- (BOOL)tapAtPoint:(CGPoint)point;
- (BOOL)swipeFrom:(CGPoint)start
               to:(CGPoint)end
         duration:(NSTimeInterval)duration;

// 获取当前使用的方法
- (NSString *)currentMethod;

@end
