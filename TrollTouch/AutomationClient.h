//
//  AutomationClient.h
//  Client for communicating with UITests automation server
//

#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

typedef void (^AutomationCompletionBlock)(BOOL success,
                                          NSError *_Nullable error);

@interface AutomationClient : NSObject

/// Shared client instance
+ (instancetype)sharedClient;

/// Check if server is reachable
- (void)checkServerStatus:(void (^)(BOOL available))completion;

/// Tap at normalized coordinates (0.0-1.0)
- (void)tapAtPoint:(CGPoint)normalizedPoint
        completion:(AutomationCompletionBlock _Nullable)completion;

/// Swipe from start to end point
- (void)swipeFrom:(CGPoint)start
               to:(CGPoint)end
         duration:(NSTimeInterval)duration
       completion:(AutomationCompletionBlock _Nullable)completion;

/// Launch an application
- (void)launchApp:(NSString *)bundleId
       completion:(AutomationCompletionBlock _Nullable)completion;

@end

NS_ASSUME_NONNULL_END
