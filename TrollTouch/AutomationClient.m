//
//  AutomationClient.m
//  Client implementation using direct method calls to UITests
//

#import "AutomationClient.h"
#import <objc/runtime.h>

@implementation AutomationClient

+ (instancetype)sharedClient {
  static AutomationClient *shared = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    shared = [[AutomationClient alloc] init];
  });
  return shared;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    NSLog(@"[AutomationClient] Initialized");
  }
  return self;
}

#pragma mark - Server Communication

- (void)checkServerStatus:(void (^)(BOOL available))completion {
  // Try to get AutomationServer class from UITests
  Class serverClass = NSClassFromString(@"AutomationServer");
  if (serverClass) {
    SEL sharedSel = NSSelectorFromString(@"sharedServer");
    if ([serverClass respondsToSelector:sharedSel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
      id server = [serverClass performSelector:sharedSel];
#pragma clang diagnostic pop

      SEL isRunningSel = NSSelectorFromString(@"isRunning");
      if ([server respondsToSelector:isRunningSel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        BOOL running = (BOOL)[server performSelector:isRunningSel];
#pragma clang diagnostic pop
        completion(running);
        return;
      }
    }
  }

  NSLog(@"[AutomationClient] ⚠️ Server not available");
  completion(NO);
}

- (void)tapAtPoint:(CGPoint)normalizedPoint
        completion:(AutomationCompletionBlock)completion {
  NSLog(@"[AutomationClient] 📤 Sending tap command: (%.3f, %.3f)",
        normalizedPoint.x, normalizedPoint.y);

  // Get AutomationServer from UITests
  Class serverClass = NSClassFromString(@"AutomationServer");
  if (!serverClass) {
    NSLog(@"[AutomationClient] ❌ AutomationServer class not found");
    if (completion) {
      NSError *error =
          [NSError errorWithDomain:@"AutomationClient"
                              code:-1
                          userInfo:@{
                            NSLocalizedDescriptionKey : @"Server not available"
                          }];
      completion(NO, error);
    }
    return;
  }

  SEL sharedSel = NSSelectorFromString(@"sharedServer");
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
  id server = [serverClass performSelector:sharedSel];
#pragma clang diagnostic pop

  if (!server) {
    NSLog(@"[AutomationClient] ❌ Failed to get server instance");
    if (completion) {
      NSError *error = [NSError
          errorWithDomain:@"AutomationClient"
                     code:-2
                 userInfo:@{
                   NSLocalizedDescriptionKey : @"Server instance not available"
                 }];
      completion(NO, error);
    }
    return;
  }

  // Call handleTapCommand:completion:
  SEL handleSel = NSSelectorFromString(@"handleTapCommand:completion:");
  if (![server respondsToSelector:handleSel]) {
    NSLog(@"[AutomationClient] ❌ handleTapCommand not found");
    if (completion) {
      NSError *error = [NSError
          errorWithDomain:@"AutomationClient"
                     code:-3
                 userInfo:@{
                   NSLocalizedDescriptionKey : @"Command handler not available"
                 }];
      completion(NO, error);
    }
    return;
  }

  NSDictionary *params =
      @{@"x" : @(normalizedPoint.x), @"y" : @(normalizedPoint.y)};

  NSMethodSignature *signature = [server methodSignatureForSelector:handleSel];
  NSInvocation *invocation =
      [NSInvocation invocationWithMethodSignature:signature];
  [invocation setTarget:server];
  [invocation setSelector:handleSel];
  [invocation setArgument:&params atIndex:2];

  void (^responseHandler)(NSDictionary *) = ^(NSDictionary *response) {
    BOOL success = [response[@"success"] boolValue];
    NSLog(@"[AutomationClient] 📥 Tap response: %@",
          success ? @"✅ Success" : @"❌ Failed");
    if (completion) {
      NSError *error =
          success
              ? nil
              : [NSError errorWithDomain:@"AutomationClient"
                                    code:-4
                                userInfo:@{
                                  NSLocalizedDescriptionKey : response[@"error"]
                                      ?: @"Unknown error"
                                }];
      completion(success, error);
    }
  };

  [invocation setArgument:&responseHandler atIndex:3];
  [invocation invoke];
}

- (void)swipeFrom:(CGPoint)start
               to:(CGPoint)end
         duration:(NSTimeInterval)duration
       completion:(AutomationCompletionBlock)completion {
  NSLog(@"[AutomationClient] 📤 Sending swipe command: (%.3f, %.3f) → (%.3f, "
        @"%.3f)",
        start.x, start.y, end.x, end.y);

  Class serverClass = NSClassFromString(@"AutomationServer");
  if (!serverClass) {
    if (completion) {
      NSError *error =
          [NSError errorWithDomain:@"AutomationClient"
                              code:-1
                          userInfo:@{
                            NSLocalizedDescriptionKey : @"Server not available"
                          }];
      completion(NO, error);
    }
    return;
  }

  SEL sharedSel = NSSelectorFromString(@"sharedServer");
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
  id server = [serverClass performSelector:sharedSel];
#pragma clang diagnostic pop

  SEL handleSel = NSSelectorFromString(@"handleSwipeCommand:completion:");
  if (![server respondsToSelector:handleSel]) {
    if (completion) {
      NSError *error = [NSError
          errorWithDomain:@"AutomationClient"
                     code:-3
                 userInfo:@{
                   NSLocalizedDescriptionKey : @"Command handler not available"
                 }];
      completion(NO, error);
    }
    return;
  }

  NSDictionary *params = @{
    @"startX" : @(start.x),
    @"startY" : @(start.y),
    @"endX" : @(end.x),
    @"endY" : @(end.y),
    @"duration" : @(duration)
  };

  NSMethodSignature *signature = [server methodSignatureForSelector:handleSel];
  NSInvocation *invocation =
      [NSInvocation invocationWithMethodSignature:signature];
  [invocation setTarget:server];
  [invocation setSelector:handleSel];
  [invocation setArgument:&params atIndex:2];

  void (^responseHandler)(NSDictionary *) = ^(NSDictionary *response) {
    BOOL success = [response[@"success"] boolValue];
    NSLog(@"[AutomationClient] 📥 Swipe response: %@",
          success ? @"✅ Success" : @"❌ Failed");
    if (completion) {
      NSError *error =
          success
              ? nil
              : [NSError errorWithDomain:@"AutomationClient"
                                    code:-4
                                userInfo:@{
                                  NSLocalizedDescriptionKey : response[@"error"]
                                      ?: @"Unknown error"
                                }];
      completion(success, error);
    }
  };

  [invocation setArgument:&responseHandler atIndex:3];
  [invocation invoke];
}

- (void)launchApp:(NSString *)bundleId
       completion:(AutomationCompletionBlock)completion {
  NSLog(@"[AutomationClient] 📤 Sending launch command: %@", bundleId);

  Class serverClass = NSClassFromString(@"AutomationServer");
  if (!serverClass) {
    if (completion) {
      NSError *error =
          [NSError errorWithDomain:@"AutomationClient"
                              code:-1
                          userInfo:@{
                            NSLocalizedDescriptionKey : @"Server not available"
                          }];
      completion(NO, error);
    }
    return;
  }

  SEL sharedSel = NSSelectorFromString(@"sharedServer");
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
  id server = [serverClass performSelector:sharedSel];
#pragma clang diagnostic pop

  SEL handleSel = NSSelectorFromString(@"handleLaunchCommand:completion:");
  if (![server respondsToSelector:handleSel]) {
    if (completion) {
      NSError *error = [NSError
          errorWithDomain:@"AutomationClient"
                     code:-3
                 userInfo:@{
                   NSLocalizedDescriptionKey : @"Command handler not available"
                 }];
      completion(NO, error);
    }
    return;
  }

  NSDictionary *params = @{@"bundleId" : bundleId};

  NSMethodSignature *signature = [server methodSignatureForSelector:handleSel];
  NSInvocation *invocation =
      [NSInvocation invocationWithMethodSignature:signature];
  [invocation setTarget:server];
  [invocation setSelector:handleSel];
  [invocation setArgument:&params atIndex:2];

  void (^responseHandler)(NSDictionary *) = ^(NSDictionary *response) {
    BOOL success = [response[@"success"] boolValue];
    NSLog(@"[AutomationClient] 📥 Launch response: %@",
          success ? @"✅ Success" : @"❌ Failed");
    if (completion) {
      NSError *error =
          success
              ? nil
              : [NSError errorWithDomain:@"AutomationClient"
                                    code:-4
                                userInfo:@{
                                  NSLocalizedDescriptionKey : response[@"error"]
                                      ?: @"Unknown error"
                                }];
      completion(success, error);
    }
  };

  [invocation setArgument:&responseHandler atIndex:3];
  [invocation invoke];
}

@end
