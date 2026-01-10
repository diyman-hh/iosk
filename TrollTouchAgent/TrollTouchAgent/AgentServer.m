//
//  AgentServer.m
//  TrollTouchAgent
//
//  Simple HTTP Server for receiving touch injection commands
//

#import "AgentServer.h"
#import "TouchInjector.h"
#import <UIKit/UIKit.h>

@interface AgentServer () <NSStreamDelegate>
@property(nonatomic, strong) NSInputStream *inputStream;
@property(nonatomic, strong) NSOutputStream *outputStream;
@property(nonatomic, assign) CFSocketRef socket;
@property(nonatomic, assign) NSUInteger port;
@property(nonatomic, assign) BOOL isRunning;
@end

@implementation AgentServer

+ (instancetype)sharedServer {
  static AgentServer *instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[AgentServer alloc] init];
  });
  return instance;
}

- (void)startServerOnPort:(NSUInteger)port {
  if (self.isRunning) {
    NSLog(@"[AgentServer] ⚠️ Server already running");
    return;
  }

  self.port = port;
  NSLog(@"[AgentServer] 🚀 Starting HTTP server on port %lu...",
        (unsigned long)port);

  // 创建 socket
  CFSocketContext context = {0, (__bridge void *)self, NULL, NULL, NULL};
  self.socket =
      CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM, IPPROTO_TCP,
                     kCFSocketAcceptCallBack, &AcceptCallback, &context);

  if (!self.socket) {
    NSLog(@"[AgentServer] ❌ Failed to create socket");
    return;
  }

  // 设置地址重用
  int yes = 1;
  setsockopt(CFSocketGetNative(self.socket), SOL_SOCKET, SO_REUSEADDR, &yes,
             sizeof(yes));

  // 绑定地址
  struct sockaddr_in addr;
  memset(&addr, 0, sizeof(addr));
  addr.sin_len = sizeof(addr);
  addr.sin_family = AF_INET;
  addr.sin_port = htons(port);
  addr.sin_addr.s_addr = htonl(INADDR_ANY);

  CFDataRef addressData =
      CFDataCreate(NULL, (const UInt8 *)&addr, sizeof(addr));
  CFSocketError error = CFSocketSetAddress(self.socket, addressData);
  CFRelease(addressData);

  if (error != kCFSocketSuccess) {
    NSLog(@"[AgentServer] ❌ Failed to bind socket: %ld", (long)error);
    CFRelease(self.socket);
    self.socket = NULL;
    return;
  }

  // 添加到 run loop
  CFRunLoopSourceRef source =
      CFSocketCreateRunLoopSource(kCFAllocatorDefault, self.socket, 0);
  CFRunLoopAddSource(CFRunLoopGetCurrent(), source, kCFRunLoopCommonModes);
  CFRelease(source);

  self.isRunning = YES;
  NSLog(@"[AgentServer] ✅ HTTP server started on port %lu",
        (unsigned long)port);
}

static void AcceptCallback(CFSocketRef socket, CFSocketCallBackType type,
                           CFDataRef address, const void *data, void *info) {
  if (type != kCFSocketAcceptCallBack) {
    return;
  }

  AgentServer *server = (__bridge AgentServer *)info;
  CFSocketNativeHandle nativeSocket = *(CFSocketNativeHandle *)data;

  NSLog(@"[AgentServer] 📥 New connection accepted");

  // 在后台线程处理请求
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                 ^{
                   [server handleConnection:nativeSocket];
                 });
}

- (void)handleConnection:(CFSocketNativeHandle)nativeSocket {
  // 读取请求
  char buffer[4096];
  ssize_t bytesRead = recv(nativeSocket, buffer, sizeof(buffer) - 1, 0);

  if (bytesRead <= 0) {
    close(nativeSocket);
    return;
  }

  buffer[bytesRead] = '\0';
  NSString *request = [NSString stringWithUTF8String:buffer];
  NSLog(@"[AgentServer] 📨 Request:\n%@", request);

  // 解析请求
  NSDictionary *response = [self processRequest:request];

  // 发送响应
  NSString *responseBody = [self jsonStringFromDictionary:response];
  NSString *httpResponse = [NSString
      stringWithFormat:@"HTTP/1.1 200 OK\r\n"
                       @"Content-Type: application/json\r\n"
                       @"Content-Length: %lu\r\n"
                       @"Access-Control-Allow-Origin: *\r\n"
                       @"\r\n"
                       @"%@",
                       (unsigned long)[responseBody length], responseBody];

  const char *responseData = [httpResponse UTF8String];
  send(nativeSocket, responseData, strlen(responseData), 0);
  close(nativeSocket);

  NSLog(@"[AgentServer] ✅ Response sent");
}

- (NSDictionary *)processRequest:(NSString *)request {
  // 简单的请求解析
  NSArray *lines = [request componentsSeparatedByString:@"\r\n"];
  if (lines.count == 0) {
    return @{@"status" : @"error", @"message" : @"Invalid request"};
  }

  NSString *requestLine = lines[0];
  NSArray *parts = [requestLine componentsSeparatedByString:@" "];
  if (parts.count < 2) {
    return @{@"status" : @"error", @"message" : @"Invalid request line"};
  }

  NSString *method = parts[0];
  NSString *path = parts[1];

  NSLog(@"[AgentServer] 🔍 %@ %@", method, path);

  // 路由处理
  if ([path isEqualToString:@"/status"]) {
    return @{
      @"status" : @"ok",
      @"message" : @"TrollTouchAgent is running",
      @"version" : @"1.0.0"
    };
  } else if ([path hasPrefix:@"/tap"]) {
    return [self handleTapRequest:path];
  } else if ([path hasPrefix:@"/swipe"]) {
    return [self handleSwipeRequest:path];
  } else {
    return @{@"status" : @"error", @"message" : @"Unknown endpoint"};
  }
}

- (NSDictionary *)handleTapRequest:(NSString *)path {
  // 解析参数: /tap?x=0.5&y=0.5
  NSDictionary *params = [self parseQueryString:path];

  CGFloat x = [params[@"x"] floatValue];
  CGFloat y = [params[@"y"] floatValue];

  NSLog(@"[AgentServer] 👆 Tap at (%.3f, %.3f)", x, y);

  // 执行触摸注入
  BOOL success = [[TouchInjector sharedInjector] tapAtPoint:CGPointMake(x, y)];

  return @{
    @"status" : success ? @"ok" : @"error",
    @"action" : @"tap",
    @"x" : @(x),
    @"y" : @(y)
  };
}

- (NSDictionary *)handleSwipeRequest:(NSString *)path {
  // 解析参数: /swipe?x1=0.5&y1=0.8&x2=0.5&y2=0.2&duration=0.25
  NSDictionary *params = [self parseQueryString:path];

  CGFloat x1 = [params[@"x1"] floatValue];
  CGFloat y1 = [params[@"y1"] floatValue];
  CGFloat x2 = [params[@"x2"] floatValue];
  CGFloat y2 = [params[@"y2"] floatValue];
  CGFloat duration = [params[@"duration"] floatValue] ?: 0.25;

  NSLog(@"[AgentServer] 👉 Swipe from (%.3f, %.3f) to (%.3f, %.3f)", x1, y1, x2,
        y2);

  // 执行触摸注入
  BOOL success = [[TouchInjector sharedInjector] swipeFrom:CGPointMake(x1, y1)
                                                        to:CGPointMake(x2, y2)
                                                  duration:duration];

  return @{
    @"status" : success ? @"ok" : @"error",
    @"action" : @"swipe",
    @"from" : @{@"x" : @(x1), @"y" : @(y1)},
    @"to" : @{@"x" : @(x2), @"y" : @(y2)},
    @"duration" : @(duration)
  };
}

- (NSDictionary *)parseQueryString:(NSString *)path {
  NSMutableDictionary *params = [NSMutableDictionary dictionary];

  NSArray *components = [path componentsSeparatedByString:@"?"];
  if (components.count < 2) {
    return params;
  }

  NSString *query = components[1];
  NSArray *pairs = [query componentsSeparatedByString:@"&"];

  for (NSString *pair in pairs) {
    NSArray *kv = [pair componentsSeparatedByString:@"="];
    if (kv.count == 2) {
      params[kv[0]] = kv[1];
    }
  }

  return params;
}

- (NSString *)jsonStringFromDictionary:(NSDictionary *)dict {
  NSError *error;
  NSData *jsonData =
      [NSJSONSerialization dataWithJSONObject:dict
                                      options:NSJSONWritingPrettyPrinted
                                        error:&error];
  if (error) {
    return @"{\"status\":\"error\"}";
  }
  return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

- (void)stopServer {
  if (!self.isRunning) {
    return;
  }

  NSLog(@"[AgentServer] 🛑 Stopping server...");

  if (self.socket) {
    CFSocketInvalidate(self.socket);
    CFRelease(self.socket);
    self.socket = NULL;
  }

  self.isRunning = NO;
  NSLog(@"[AgentServer] ✅ Server stopped");
}

@end
