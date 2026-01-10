//
//  AgentClient.m
//  TrollTouch
//
//  Client for communicating with TrollTouchAgent via App Groups
//

#import "AgentClient.h"
#import "SharedCommandQueue.h"

@implementation AgentClient

+ (instancetype)sharedClient {
  static AgentClient *instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[AgentClient alloc] init];
  });
  return instance;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    NSLog(@"[AgentClient] 🔧 Initialized with App Groups IPC");
  }
  return self;
}

- (void)connectToAgent {
  NSLog(@"[AgentClient] 🔌 Using App Groups - always connected");
}

- (BOOL)isConnected {
  return YES; // App Groups is always "connected"
}

- (void)disconnect {
  NSLog(@"[AgentClient] 🔌 App Groups - no disconnection needed");
}

#pragma mark - Touch Operations

- (void)tapAtPoint:(CGPoint)point
        completion:(void (^)(BOOL success, NSError *error))completion {
  NSLog(@"[AgentClient] 👆 Requesting tap at (%.3f, %.3f) via App Groups",
        point.x, point.y);

  [[SharedCommandQueue sharedQueue]
      sendTapCommand:point
          completion:^(BOOL success, NSError *error) {
            if (success) {
              NSLog(@"[AgentClient] ✅ Tap SUCCESS");
            } else {
              NSLog(@"[AgentClient] ❌ Tap FAILED: %@",
                    error.localizedDescription);
            }
            if (completion)
              completion(success, error);
          }];
}

- (void)swipeFrom:(CGPoint)start
               to:(CGPoint)end
         duration:(NSTimeInterval)duration
       completion:(void (^)(BOOL success, NSError *error))completion {
  NSLog(@"[AgentClient] 👉 Requesting swipe from (%.3f, %.3f) to (%.3f, %.3f) "
        @"via App Groups",
        start.x, start.y, end.x, end.y);

  [[SharedCommandQueue sharedQueue]
      sendSwipeCommand:start
                    to:end
              duration:duration
            completion:^(BOOL success, NSError *error) {
              if (success) {
                NSLog(@"[AgentClient] ✅ Swipe SUCCESS");
              } else {
                NSLog(@"[AgentClient] ❌ Swipe FAILED: %@",
                      error.localizedDescription);
              }
              if (completion)
                completion(success, error);
            }];
}

- (void)checkStatus:(void (^)(BOOL online, NSDictionary *info))completion {
  // App Groups is always available
  if (completion) {
    completion(YES, @{
      @"status" : @"ok",
      @"method" : @"App Groups + Darwin Notifications",
      @"version" : @"2.0.0"
    });
  }
}

@end
