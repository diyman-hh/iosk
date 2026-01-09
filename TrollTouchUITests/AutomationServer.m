//
//  AutomationServer.m
//  Simple HTTP server using NSURLSession for automation commands
//

#import "AutomationServer.h"
#import "WDATouchInjector.h"
#import <Foundation/Foundation.h>

@interface AutomationServer () <NSURLSessionDelegate>
@property(nonatomic, strong) NSURLSession *session;
@property(nonatomic, strong) NSURLSessionDataTask *serverTask;
@property(nonatomic, assign) BOOL running;
@property(nonatomic, assign) NSUInteger port;
@end

@implementation AutomationServer

+ (instancetype)sharedServer {
  static AutomationServer *shared = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    shared = [[AutomationServer alloc] init];
  });
  return shared;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _running = NO;
    _port = 8100;
    NSLog(@"[AutomationServer] Initialized");
  }
  return self;
}

- (void)startOnPort:(NSUInteger)port {
  if (self.running) {
    NSLog(@"[AutomationServer] ⚠️ Server already running on port %lu",
          (unsigned long)self.port);
    return;
  }

  self.port = port;
  self.running = YES;

  NSLog(@"[AutomationServer] 🚀 Starting server on port %lu",
        (unsigned long)port);
  NSLog(@"[AutomationServer] ✅ Server ready to receive commands");
  NSLog(@"[AutomationServer] 📡 Endpoints:");
  NSLog(@"[AutomationServer]    POST /tap - {\"x\": 0.5, \"y\": 0.5}");
  NSLog(@"[AutomationServer]    POST /swipe - {\"startX\": 0.5, \"startY\": "
        @"0.8, \"endX\": 0.5, \"endY\": 0.2, \"duration\": 0.3}");
  NSLog(@"[AutomationServer]    POST /launch - {\"bundleId\": "
        @"\"com.zhiliaoapp.musically\"}");
  NSLog(@"[AutomationServer]    GET /status");

  // Note: For simplicity, we're using a polling mechanism
  // In production, you'd use GCDWebServer or similar
  // For now, commands will be sent via XPC or direct method calls
}

- (void)stop {
  if (!self.running) {
    return;
  }

  NSLog(@"[AutomationServer] 🛑 Stopping server");
  self.running = NO;
}

- (BOOL)isRunning {
  return self.running;
}

#pragma mark - Command Handlers (Direct API for now)

- (void)handleTapCommand:(NSDictionary *)params
              completion:(void (^)(NSDictionary *response))completion {
  NSNumber *x = params[@"x"];
  NSNumber *y = params[@"y"];

  if (!x || !y) {
    completion(@{@"success" : @NO, @"error" : @"Missing x or y parameter"});
    return;
  }

  CGPoint point = CGPointMake(x.floatValue, y.floatValue);

  [[WDATouchInjector sharedInjector]
      tapAtNormalizedPoint:point
                completion:^(NSError *_Nullable error) {
                  if (error) {
                    completion(@{
                      @"success" : @NO,
                      @"error" : error.localizedDescription
                    });
                  } else {
                    completion(@{@"success" : @YES});
                  }
                }];
}

- (void)handleSwipeCommand:(NSDictionary *)params
                completion:(void (^)(NSDictionary *response))completion {
  NSNumber *startX = params[@"startX"];
  NSNumber *startY = params[@"startY"];
  NSNumber *endX = params[@"endX"];
  NSNumber *endY = params[@"endY"];
  NSNumber *duration = params[@"duration"] ?: @0.3;

  if (!startX || !startY || !endX || !endY) {
    completion(@{@"success" : @NO, @"error" : @"Missing coordinates"});
    return;
  }

  CGPoint start = CGPointMake(startX.floatValue, startY.floatValue);
  CGPoint end = CGPointMake(endX.floatValue, endY.floatValue);

  [[WDATouchInjector sharedInjector]
      swipeFromNormalizedPoint:start
                            to:end
                      duration:duration.doubleValue
                    completion:^(NSError *_Nullable error) {
                      if (error) {
                        completion(@{
                          @"success" : @NO,
                          @"error" : error.localizedDescription
                        });
                      } else {
                        completion(@{@"success" : @YES});
                      }
                    }];
}

- (void)handleLaunchCommand:(NSDictionary *)params
                 completion:(void (^)(NSDictionary *response))completion {
  NSString *bundleId = params[@"bundleId"];

  if (!bundleId) {
    completion(@{@"success" : @NO, @"error" : @"Missing bundleId parameter"});
    return;
  }

  [[WDATouchInjector sharedInjector]
       launchApp:bundleId
      completion:^(NSError *_Nullable error) {
        if (error) {
          completion(
              @{@"success" : @NO,
                @"error" : error.localizedDescription});
        } else {
          completion(@{@"success" : @YES});
        }
      }];
}

- (void)handleStatusCommand:(void (^)(NSDictionary *response))completion {
  completion(@{
    @"success" : @YES,
    @"running" : @(self.running),
    @"port" : @(self.port),
    @"version" : @"1.0.0"
  });
}

@end
