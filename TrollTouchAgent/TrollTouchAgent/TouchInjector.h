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

// Status for UI
@property(nonatomic, readonly) BOOL iohidLoaded;
@property(nonatomic, readonly) BOOL gsLoaded;
@property(nonatomic, readonly) NSString *statusString;
@property(nonatomic, readonly) NSString *currentMethod;

@end
