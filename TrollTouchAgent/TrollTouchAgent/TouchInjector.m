//
//  TouchInjector.m
//  TrollTouchAgent
//
//  Multi-method touch injection implementation
//

#import "TouchInjector.h"
#import <UIKit/UIKit.h>
#import <dlfcn.h>
#import <mach/mach.h>

// IOHIDEvent 类型定义
typedef struct __IOHIDEvent *IOHIDEventRef;
typedef struct __IOHIDEventSystemClient *IOHIDEventSystemClientRef;

// 函数指针类型
typedef IOHIDEventSystemClientRef (*IOHIDEventSystemClientCreateFunc)(
    CFAllocatorRef);
typedef IOHIDEventRef (*IOHIDEventCreateDigitizerEventFunc)(
    CFAllocatorRef, uint64_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t,
    CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, Boolean, Boolean);
typedef void (*IOHIDEventSetSenderIDFunc)(IOHIDEventRef, uint64_t);
typedef void (*IOHIDEventSystemClientDispatchEventFunc)(
    IOHIDEventSystemClientRef, IOHIDEventRef);
typedef void (*IOHIDEventSetIntegerValueFunc)(IOHIDEventRef, uint32_t, int32_t);

// GraphicsServices 函数
typedef mach_port_t (*GSGetPurpleApplicationPortFunc)(void);
typedef void (*GSSendEventFunc)(void *, mach_port_t);

@interface TouchInjector () {
  // IOHIDEvent 方法
  void *_ioKitHandle;
  IOHIDEventSystemClientRef _client;
  uint64_t _digitizerServiceID;
  IOHIDEventSystemClientCreateFunc _IOHIDEventSystemClientCreate;
  IOHIDEventCreateDigitizerEventFunc _IOHIDEventCreateDigitizerEvent;
  IOHIDEventSetSenderIDFunc _IOHIDEventSetSenderID;
  IOHIDEventSystemClientDispatchEventFunc _IOHIDEventSystemClientDispatchEvent;
  IOHIDEventSetIntegerValueFunc _IOHIDEventSetIntegerValue;

  // GraphicsServices 方法
  void *_gsHandle;
  GSGetPurpleApplicationPortFunc _GSGetPurpleApplicationPort;
  GSSendEventFunc _GSSendEvent;
  mach_port_t _purplePort;
}

@property(nonatomic, copy) NSString *currentMethod;

@end

@implementation TouchInjector

+ (instancetype)sharedInjector {
  static TouchInjector *instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[TouchInjector alloc] init];
  });
  return instance;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    // 尝试初始化多种方法
    [self initializeIOHIDEvent];
    [self initializeGraphicsServices];
  }
  return self;
}

#pragma mark - IOHIDEvent 方法

- (void)initializeIOHIDEvent {
  NSLog(@"[TouchInjector] 🔧 Initializing IOHIDEvent method...");

  _ioKitHandle =
      dlopen("/System/Library/Frameworks/IOKit.framework/IOKit", RTLD_LAZY);
  if (!_ioKitHandle) {
    NSLog(@"[TouchInjector] ❌ Failed to load IOKit");
    return;
  }

  _IOHIDEventSystemClientCreate = (IOHIDEventSystemClientCreateFunc)dlsym(
      _ioKitHandle, "IOHIDEventSystemClientCreate");
  _IOHIDEventCreateDigitizerEvent = (IOHIDEventCreateDigitizerEventFunc)dlsym(
      _ioKitHandle, "IOHIDEventCreateDigitizerEvent");
  _IOHIDEventSetSenderID =
      (IOHIDEventSetSenderIDFunc)dlsym(_ioKitHandle, "IOHIDEventSetSenderID");
  _IOHIDEventSystemClientDispatchEvent =
      (IOHIDEventSystemClientDispatchEventFunc)dlsym(
          _ioKitHandle, "IOHIDEventSystemClientDispatchEvent");
  _IOHIDEventSetIntegerValue = (IOHIDEventSetIntegerValueFunc)dlsym(
      _ioKitHandle, "IOHIDEventSetIntegerValue");

  if (_IOHIDEventSystemClientCreate) {
    _client = _IOHIDEventSystemClientCreate(kCFAllocatorDefault);
    _digitizerServiceID = 0x8000000817319372; // 固定 ID
    NSLog(@"[TouchInjector] ✅ IOHIDEvent initialized");
    self.currentMethod = @"IOHIDEvent";
  } else {
    NSLog(@"[TouchInjector] ❌ IOHIDEvent functions not found");
  }
}

#pragma mark - GraphicsServices 方法

- (void)initializeGraphicsServices {
  NSLog(@"[TouchInjector] 🔧 Initializing GraphicsServices method...");

  _gsHandle = dlopen("/System/Library/PrivateFrameworks/"
                     "GraphicsServices.framework/GraphicsServices",
                     RTLD_LAZY);
  if (!_gsHandle) {
    NSLog(@"[TouchInjector] ❌ Failed to load GraphicsServices");
    return;
  }

  _GSGetPurpleApplicationPort = (GSGetPurpleApplicationPortFunc)dlsym(
      _gsHandle, "GSGetPurpleApplicationPort");
  _GSSendEvent = (GSSendEventFunc)dlsym(_gsHandle, "GSSendEvent");

  if (_GSGetPurpleApplicationPort && _GSSendEvent) {
    _purplePort = _GSGetPurpleApplicationPort();
    NSLog(@"[TouchInjector] ✅ GraphicsServices initialized, port: %d",
          _purplePort);
    if (!self.currentMethod) {
      self.currentMethod = @"GraphicsServices";
    }
  } else {
    NSLog(@"[TouchInjector] ❌ GraphicsServices functions not found");
  }
}

#pragma mark - 触摸注入接口

- (BOOL)tapAtPoint:(CGPoint)point {
  NSLog(@"[TouchInjector] 👆 Tap at (%.3f, %.3f) using %@", point.x, point.y,
        self.currentMethod);

  // 尝试多种方法
  BOOL success = NO;

  // 方法 1: IOHIDEvent
  if (_client && _IOHIDEventCreateDigitizerEvent) {
    success = [self tapUsingIOHIDEvent:point];
    if (success)
      return YES;
  }

  // 方法 2: GraphicsServices
  if (_purplePort && _GSSendEvent) {
    success = [self tapUsingGraphicsServices:point];
    if (success)
      return YES;
  }

  // 方法 3: UIAutomation (如果可用)
  success = [self tapUsingUIAutomation:point];

  return success;
}

- (BOOL)swipeFrom:(CGPoint)start
               to:(CGPoint)end
         duration:(NSTimeInterval)duration {
  NSLog(@"[TouchInjector] 👉 Swipe from (%.3f, %.3f) to (%.3f, %.3f) using %@",
        start.x, start.y, end.x, end.y, self.currentMethod);

  // 尝试多种方法
  BOOL success = NO;

  // 方法 1: IOHIDEvent
  if (_client && _IOHIDEventCreateDigitizerEvent) {
    success = [self swipeUsingIOHIDEvent:start to:end duration:duration];
    if (success)
      return YES;
  }

  // 方法 2: GraphicsServices
  if (_purplePort && _GSSendEvent) {
    success = [self swipeUsingGraphicsServices:start to:end duration:duration];
    if (success)
      return YES;
  }

  // 方法 3: UIAutomation
  success = [self swipeUsingUIAutomation:start to:end duration:duration];

  return success;
}

#pragma mark - IOHIDEvent 实现

- (BOOL)tapUsingIOHIDEvent:(CGPoint)point {
  if (!_client || !_IOHIDEventCreateDigitizerEvent) {
    return NO;
  }

  // 按下
  [self sendIOHIDEventAtPoint:point type:1];
  usleep(50000); // 50ms

  // 抬起
  [self sendIOHIDEventAtPoint:point type:3];

  return YES;
}

- (BOOL)swipeUsingIOHIDEvent:(CGPoint)start
                          to:(CGPoint)end
                    duration:(NSTimeInterval)duration {
  if (!_client || !_IOHIDEventCreateDigitizerEvent) {
    return NO;
  }

  int steps = 15;
  NSTimeInterval stepDuration = duration / steps;

  // 按下
  [self sendIOHIDEventAtPoint:start type:1];
  usleep(20000);

  // 移动
  for (int i = 0; i <= steps; i++) {
    CGFloat progress = (CGFloat)i / steps;
    CGPoint current = CGPointMake(start.x + (end.x - start.x) * progress,
                                  start.y + (end.y - start.y) * progress);
    [self sendIOHIDEventAtPoint:current type:2];
    usleep(stepDuration * 1000000);
  }

  // 抬起
  [self sendIOHIDEventAtPoint:end type:3];

  return YES;
}

- (void)sendIOHIDEventAtPoint:(CGPoint)point type:(int)type {
  uint64_t timestamp = mach_absolute_time();
  Boolean range = (type != 3);
  Boolean touch = (type == 1 || type == 2);

  // 转换为屏幕坐标
  CGRect screenBounds = [[UIScreen mainScreen] bounds];
  CGFloat scale = [[UIScreen mainScreen] scale];
  CGFloat x = point.x * screenBounds.size.width;
  CGFloat y = point.y * screenBounds.size.height;

  IOHIDEventRef event = _IOHIDEventCreateDigitizerEvent(
      kCFAllocatorDefault, timestamp,
      2, // kIOHIDDigitizerTransducerTypeFinger
      0, 2, 0, 0, x, y, 0, 0.5, 0, 0, range, touch);

  if (event) {
    _IOHIDEventSetSenderID(event, _digitizerServiceID);
    _IOHIDEventSystemClientDispatchEvent(_client, event);
    CFRelease(event);
  }
}

#pragma mark - GraphicsServices 实现

- (BOOL)tapUsingGraphicsServices:(CGPoint)point {
  NSLog(@"[TouchInjector] 🔧 Trying GraphicsServices tap...");
  // TODO: 实现 GSEvent 创建和发送
  return NO;
}

- (BOOL)swipeUsingGraphicsServices:(CGPoint)start
                                to:(CGPoint)end
                          duration:(NSTimeInterval)duration {
  NSLog(@"[TouchInjector] 🔧 Trying GraphicsServices swipe...");
  // TODO: 实现 GSEvent 创建和发送
  return NO;
}

#pragma mark - UIAutomation 实现

- (BOOL)tapUsingUIAutomation:(CGPoint)point {
  NSLog(@"[TouchInjector] 🔧 Trying UIAutomation tap...");
  // TODO: 尝试使用 Accessibility API
  return NO;
}

- (BOOL)swipeUsingUIAutomation:(CGPoint)start
                            to:(CGPoint)end
                      duration:(NSTimeInterval)duration {
  NSLog(@"[TouchInjector] 🔧 Trying UIAutomation swipe...");
  // TODO: 尝试使用 Accessibility API
  return NO;
}

- (void)dealloc {
  if (_ioKitHandle) {
    dlclose(_ioKitHandle);
  }
  if (_gsHandle) {
    dlclose(_gsHandle);
  }
}

@end
