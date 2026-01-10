//
//  AgentClient.h
//  TrollTouch
//
//  HTTP client for communicating with TrollTouchAgent
//

#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>


@interface AgentClient : NSObject

+ (instancetype)sharedClient;

// 连接管理
- (void)connectToAgent;
- (BOOL)isConnected;
- (void)disconnect;

// 触摸操作
- (void)tapAtPoint:(CGPoint)point
        completion:(void (^)(BOOL success, NSError *error))completion;
- (void)swipeFrom:(CGPoint)start
               to:(CGPoint)end
         duration:(NSTimeInterval)duration
       completion:(void (^)(BOOL success, NSError *error))completion;

// 状态检查
- (void)checkStatus:(void (^)(BOOL online, NSDictionary *info))completion;

@end
