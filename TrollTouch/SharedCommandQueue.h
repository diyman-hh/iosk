//
//  SharedCommandQueue.h
//  TrollTouch
//
//  App Groups + Darwin Notifications based IPC
//

#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>


@interface SharedCommandQueue : NSObject

+ (instancetype)sharedQueue;

// Send command (Main App)
- (void)sendTapCommand:(CGPoint)point
            completion:(void (^)(BOOL success, NSError *error))completion;
- (void)sendSwipeCommand:(CGPoint)from
                      to:(CGPoint)to
                duration:(NSTimeInterval)duration
              completion:(void (^)(BOOL success, NSError *error))completion;

// Start listening for commands (Agent)
- (void)startListeningWithHandler:(void (^)(NSDictionary *command))handler;
- (void)stopListening;

// Send response (Agent)
- (void)sendResponse:(NSDictionary *)response;

@end
