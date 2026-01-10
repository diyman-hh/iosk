//
//  AgentClient.m
//  TrollTouch
//
//  HTTP client for communicating with TrollTouchAgent
//

#import "AgentClient.h"

@interface AgentClient ()
@property(nonatomic, copy) NSString *baseURL;
@property(nonatomic, assign) BOOL connected;
@property(nonatomic, strong) NSURLSession *session;
@end

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
    self.baseURL = @"http://localhost:8100";
    self.connected = NO;

    NSURLSessionConfiguration *config =
        [NSURLSessionConfiguration defaultSessionConfiguration];
    config.timeoutIntervalForRequest = 5.0;
    config.timeoutIntervalForResource = 10.0;
    self.session = [NSURLSession sessionWithConfiguration:config];

    NSLog(@"[AgentClient] 🔧 Initialized with base URL: %@", self.baseURL);
  }
  return self;
}

- (void)connectToAgent {
  NSLog(@"[AgentClient] 🔌 Connecting to Agent...");

  [self checkStatus:^(BOOL online, NSDictionary *info) {
    if (online) {
      self.connected = YES;
      NSLog(@"[AgentClient] ✅ Connected to Agent: %@", info);
    } else {
      self.connected = NO;
      NSLog(@"[AgentClient] ❌ Failed to connect to Agent");
    }
  }];
}

- (BOOL)isConnected {
  return self.connected;
}

- (void)disconnect {
  self.connected = NO;
  NSLog(@"[AgentClient] 🔌 Disconnected from Agent");
}

#pragma mark - Touch Operations

- (void)tapAtPoint:(CGPoint)point
        completion:(void (^)(BOOL success, NSError *error))completion {
  NSString *urlString = [NSString
      stringWithFormat:@"%@/tap?x=%.3f&y=%.3f", self.baseURL, point.x, point.y];

  NSLog(@"[AgentClient] 👆 Requesting tap at (%.3f, %.3f)", point.x, point.y);

  [self sendRequest:urlString
         completion:^(NSDictionary *response, NSError *error) {
           if (error) {
             NSLog(@"[AgentClient] ❌ Tap failed: %@", error);
             if (completion)
               completion(NO, error);
             return;
           }

           BOOL success = [response[@"status"] isEqualToString:@"ok"];
           NSLog(@"[AgentClient] %@ Tap response: %@", success ? @"✅" : @"❌",
                 response);

           if (completion)
             completion(success, nil);
         }];
}

- (void)swipeFrom:(CGPoint)start
               to:(CGPoint)end
         duration:(NSTimeInterval)duration
       completion:(void (^)(BOOL success, NSError *error))completion {
  NSString *urlString =
      [NSString stringWithFormat:
                    @"%@/swipe?x1=%.3f&y1=%.3f&x2=%.3f&y2=%.3f&duration=%.2f",
                    self.baseURL, start.x, start.y, end.x, end.y, duration];

  NSLog(@"[AgentClient] 👉 Requesting swipe from (%.3f, %.3f) to (%.3f, %.3f)",
        start.x, start.y, end.x, end.y);

  [self sendRequest:urlString
         completion:^(NSDictionary *response, NSError *error) {
           if (error) {
             NSLog(@"[AgentClient] ❌ Swipe failed: %@", error);
             if (completion)
               completion(NO, error);
             return;
           }

           BOOL success = [response[@"status"] isEqualToString:@"ok"];
           NSLog(@"[AgentClient] %@ Swipe response: %@",
                 success ? @"✅" : @"❌", response);

           if (completion)
             completion(success, nil);
         }];
}

- (void)checkStatus:(void (^)(BOOL online, NSDictionary *info))completion {
  NSString *urlString = [NSString stringWithFormat:@"%@/status", self.baseURL];

  [self sendRequest:urlString
         completion:^(NSDictionary *response, NSError *error) {
           if (error) {
             if (completion)
               completion(NO, nil);
             return;
           }

           BOOL online = [response[@"status"] isEqualToString:@"ok"];
           if (completion)
             completion(online, response);
         }];
}

#pragma mark - HTTP Request

- (void)sendRequest:(NSString *)urlString
         completion:
             (void (^)(NSDictionary *response, NSError *error))completion {
  NSURL *url = [NSURL URLWithString:urlString];
  if (!url) {
    NSError *error =
        [NSError errorWithDomain:@"AgentClient"
                            code:-1
                        userInfo:@{NSLocalizedDescriptionKey : @"Invalid URL"}];
    if (completion)
      completion(nil, error);
    return;
  }

  NSURLRequest *request = [NSURLRequest requestWithURL:url];

  NSURLSessionDataTask *task = [self.session
      dataTaskWithRequest:request
        completionHandler:^(NSData *data, NSURLResponse *response,
                            NSError *error) {
          if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
              if (completion)
                completion(nil, error);
            });
            return;
          }

          if (!data) {
            NSError *noDataError = [NSError
                errorWithDomain:@"AgentClient"
                           code:-2
                       userInfo:@{
                         NSLocalizedDescriptionKey : @"No data received"
                       }];
            dispatch_async(dispatch_get_main_queue(), ^{
              if (completion)
                completion(nil, noDataError);
            });
            return;
          }

          NSError *jsonError;
          NSDictionary *json =
              [NSJSONSerialization JSONObjectWithData:data
                                              options:0
                                                error:&jsonError];

          dispatch_async(dispatch_get_main_queue(), ^{
            if (jsonError) {
              if (completion)
                completion(nil, jsonError);
            } else {
              if (completion)
                completion(json, nil);
            }
          });
        }];

  [task resume];
}

@end
