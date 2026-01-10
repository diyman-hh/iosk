//
//  SharedCommandQueue.m
//  TrollTouch
//
//  App Groups + Darwin Notifications based IPC
//

#import "SharedCommandQueue.h"
#import <notify.h>

#define COMMAND_NOTIFICATION "com.trolltouch.command"
#define RESPONSE_NOTIFICATION "com.trolltouch.response"
#define APP_GROUP_ID @"group.com.trolltouch.shared"

@interface SharedCommandQueue ()
@property(nonatomic, strong) NSUserDefaults *sharedDefaults;
@property(nonatomic, copy) void (^commandHandler)(NSDictionary *command);
@property(nonatomic, assign) int commandToken;
@property(nonatomic, assign) int responseToken;
@property(nonatomic, strong) NSMutableDictionary *pendingCompletions;
@property(nonatomic, strong) dispatch_queue_t queue;
@end

@implementation SharedCommandQueue

+ (instancetype)sharedQueue {
  static SharedCommandQueue *instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[SharedCommandQueue alloc] init];
  });
  return instance;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    self.sharedDefaults =
        [[NSUserDefaults alloc] initWithSuiteName:APP_GROUP_ID];
    self.pendingCompletions = [NSMutableDictionary dictionary];
    self.queue =
        dispatch_queue_create("com.trolltouch.ipc", DISPATCH_QUEUE_SERIAL);

    NSLog(@"[SharedCommandQueue] 🔧 Initialized with App Group: %@",
          APP_GROUP_ID);

    // Register for response notifications (Main App)
    __weak typeof(self) weakSelf = self;
    notify_register_dispatch(RESPONSE_NOTIFICATION, &_responseToken, self.queue,
                             ^(int token) {
                               [weakSelf handleResponse];
                             });
  }
  return self;
}

#pragma mark - Send Commands (Main App)

- (void)sendTapCommand:(CGPoint)point
            completion:(void (^)(BOOL success, NSError *error))completion {
  NSDictionary *command = @{
    @"action" : @"tap",
    @"x" : @(point.x),
    @"y" : @(point.y),
    @"timestamp" : @([[NSDate date] timeIntervalSince1970]),
    @"commandId" : [[NSUUID UUID] UUIDString]
  };

  [self sendCommand:command completion:completion];
}

- (void)sendSwipeCommand:(CGPoint)from
                      to:(CGPoint)to
                duration:(NSTimeInterval)duration
              completion:(void (^)(BOOL success, NSError *error))completion {
  NSDictionary *command = @{
    @"action" : @"swipe",
    @"x1" : @(from.x),
    @"y1" : @(from.y),
    @"x2" : @(to.x),
    @"y2" : @(to.y),
    @"duration" : @(duration),
    @"timestamp" : @([[NSDate date] timeIntervalSince1970]),
    @"commandId" : [[NSUUID UUID] UUIDString]
  };

  [self sendCommand:command completion:completion];
}

- (void)sendCommand:(NSDictionary *)command
         completion:(void (^)(BOOL success, NSError *error))completion {
  dispatch_async(self.queue, ^{
    NSString *commandId = command[@"commandId"];

    // Store completion handler
    if (completion) {
      self.pendingCompletions[commandId] = [completion copy];
    }

    // Write command to shared storage
    [self.sharedDefaults setObject:command forKey:@"current_command"];
    [self.sharedDefaults synchronize];

    NSLog(@"[SharedCommandQueue] 📤 Sent command: %@", command[@"action"]);

    // Send Darwin notification to Agent
    notify_post(COMMAND_NOTIFICATION);

    // Set timeout
    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), self.queue, ^{
          void (^timeoutCompletion)(BOOL, NSError *) =
              self.pendingCompletions[commandId];
          if (timeoutCompletion) {
            [self.pendingCompletions removeObjectForKey:commandId];
            NSError *error =
                [NSError errorWithDomain:@"SharedCommandQueue"
                                    code:-1
                                userInfo:@{
                                  NSLocalizedDescriptionKey : @"Command timeout"
                                }];
            dispatch_async(dispatch_get_main_queue(), ^{
              timeoutCompletion(NO, error);
            });
          }
        });
  });
}

#pragma mark - Receive Responses (Main App)

- (void)handleResponse {
  NSDictionary *response =
      [self.sharedDefaults objectForKey:@"current_response"];
  if (!response) {
    return;
  }

  NSLog(@"[SharedCommandQueue] 📥 Received response: %@", response);

  NSString *commandId = response[@"commandId"];
  void (^completion)(BOOL, NSError *) = self.pendingCompletions[commandId];

  if (completion) {
    [self.pendingCompletions removeObjectForKey:commandId];

    BOOL success = [response[@"success"] boolValue];
    NSError *error = nil;
    if (!success && response[@"error"]) {
      error = [NSError
          errorWithDomain:@"SharedCommandQueue"
                     code:-2
                 userInfo:@{NSLocalizedDescriptionKey : response[@"error"]}];
    }

    dispatch_async(dispatch_get_main_queue(), ^{
      completion(success, error);
    });
  }

  // Clear response
  [self.sharedDefaults removeObjectForKey:@"current_response"];
  [self.sharedDefaults synchronize];
}

#pragma mark - Listen for Commands (Agent)

- (void)startListeningWithHandler:(void (^)(NSDictionary *command))handler {
  self.commandHandler = handler;

  __weak typeof(self) weakSelf = self;
  notify_register_dispatch(COMMAND_NOTIFICATION, &_commandToken, self.queue,
                           ^(int token) {
                             [weakSelf handleCommand];
                           });

  NSLog(@"[SharedCommandQueue] 👂 Started listening for commands");
}

- (void)handleCommand {
  NSDictionary *command = [self.sharedDefaults objectForKey:@"current_command"];
  if (!command) {
    return;
  }

  NSLog(@"[SharedCommandQueue] 📥 Received command: %@", command[@"action"]);

  if (self.commandHandler) {
    dispatch_async(dispatch_get_main_queue(), ^{
      self.commandHandler(command);
    });
  }

  // Clear command
  [self.sharedDefaults removeObjectForKey:@"current_command"];
  [self.sharedDefaults synchronize];
}

- (void)stopListening {
  if (self.commandToken != 0) {
    notify_cancel(self.commandToken);
    self.commandToken = 0;
  }
  NSLog(@"[SharedCommandQueue] 🛑 Stopped listening");
}

#pragma mark - Send Response (Agent)

- (void)sendResponse:(NSDictionary *)response {
  dispatch_async(self.queue, ^{
    [self.sharedDefaults setObject:response forKey:@"current_response"];
    [self.sharedDefaults synchronize];

    NSLog(@"[SharedCommandQueue] 📤 Sent response: %@", response[@"success"]);

    notify_post(RESPONSE_NOTIFICATION);
  });
}

- (void)dealloc {
  [self stopListening];
  if (self.responseToken != 0) {
    notify_cancel(self.responseToken);
  }
}

@end
