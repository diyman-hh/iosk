//
//  TouchInjector.m
//  TrollTouchAgent
//
//  Multi-method touch injection implementation
//

#import "TouchInjector.h"
#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>
#import <dlfcn.h>
#import <mach/mach.h>


// IOHIDEvent Types
typedef struct __IOHIDEvent *IOHIDEventRef;
typedef struct __IOHIDEventSystemClient *IOHIDEventSystemClientRef;

// Function Pointer Types
typedef IOHIDEventSystemClientRef (*IOHIDEventSystemClientCreateFunc)(
    CFAllocatorRef);

// Corrected signature: 5 floats (x,y,z,tip,barrel), then boolean range, boolean
// touch, int options
typedef IOHIDEventRef (*IOHIDEventCreateDigitizerEventFunc)(
    CFAllocatorRef, uint64_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t,
    CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, Boolean, Boolean, uint32_t);

typedef void (*IOHIDEventSetSenderIDFunc)(IOHIDEventRef, uint64_t);
typedef void (*IOHIDEventSystemClientDispatchEventFunc)(
    IOHIDEventSystemClientRef, IOHIDEventRef);
typedef void (*IOHIDEventSetIntegerValueFunc)(IOHIDEventRef, uint32_t, int32_t);

// GraphicsServices Types
typedef struct GSEventRecord {
  int32_t type;
  int32_t subtype;
  CGPoint location;
  CGPoint windowLocation;
  int32_t windowContextID;
  uint64_t timestamp;
  uint32_t pid;
  uint32_t flags;
  uint8_t senderPID;
  uint8_t infoSize;
} GSEventRecord;

typedef void (*GSSendSysEventFunc)(const GSEventRecord *);

@interface TouchInjector () {
  // IOHIDEvent Handles
  void *_ioKitHandle;
  IOHIDEventSystemClientRef _client;
  uint64_t _digitizerServiceID;
  IOHIDEventSystemClientCreateFunc _IOHIDEventSystemClientCreate;
  IOHIDEventCreateDigitizerEventFunc _IOHIDEventCreateDigitizerEvent;
  IOHIDEventSetSenderIDFunc _IOHIDEventSetSenderID;
  IOHIDEventSystemClientDispatchEventFunc _IOHIDEventSystemClientDispatchEvent;
  IOHIDEventSetIntegerValueFunc _IOHIDEventSetIntegerValue;

  // GraphicsServices Handles
  void *_gsHandle;
  GSSendSysEventFunc _GSSendSysEvent;
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
    [self initializeIOHIDEvent];
    [self initializeGraphicsServices];
  }
  return self;
}

#pragma mark - Initialization

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

  if (_IOHIDEventSystemClientCreate && _IOHIDEventCreateDigitizerEvent) {
    _client = _IOHIDEventSystemClientCreate(kCFAllocatorDefault);
    _digitizerServiceID = 0x8000000817319372; // Generic ID
    NSLog(@"[TouchInjector] ✅ IOHIDEvent initialized");
    self.currentMethod = @"IOHIDEvent";
  } else {
    NSLog(@"[TouchInjector] ❌ IOHIDEvent functions not found: create=%p, "
          @"digitizer=%p",
          _IOHIDEventSystemClientCreate, _IOHIDEventCreateDigitizerEvent);
  }
}

- (void)initializeGraphicsServices {
  NSLog(@"[TouchInjector] 🔧 Initializing GraphicsServices method...");

  _gsHandle = dlopen("/System/Library/PrivateFrameworks/"
                     "GraphicsServices.framework/GraphicsServices",
                     RTLD_LAZY);
  if (!_gsHandle)
    return;

  _GSSendSysEvent = (GSSendSysEventFunc)dlsym(_gsHandle, "GSSendSysEvent");

  if (_GSSendSysEvent) {
    NSLog(@"[TouchInjector] ✅ GraphicsServices (GSSendSysEvent) found");
  }
}

#pragma mark - Public Methods

- (BOOL)tapAtPoint:(CGPoint)point {
  NSLog(@"[TouchInjector] 👆 Tap (%.2f, %.2f) via %@", point.x, point.y,
        self.currentMethod);

  if (_client && _IOHIDEventCreateDigitizerEvent) {
    return [self tapUsingIOHIDEvent:point];
  }
  return NO;
}

- (BOOL)swipeFrom:(CGPoint)start
               to:(CGPoint)end
         duration:(NSTimeInterval)duration {
  NSLog(@"[TouchInjector] 👉 Swipe (%.2f, %.2f) -> (%.2f, %.2f) via %@",
        start.x, start.y, end.x, end.y, self.currentMethod);

  if (_client && _IOHIDEventCreateDigitizerEvent) {
    return [self swipeUsingIOHIDEvent:start to:end duration:duration];
  }
  return NO;
}

#pragma mark - IOHIDEvent Implementation

- (BOOL)tapUsingIOHIDEvent:(CGPoint)point {
  [self sendIOHIDEventAtPoint:point type:1]; // Down
  usleep(60000);                             // 60ms
  [self sendIOHIDEventAtPoint:point type:3]; // Up
  return YES;
}

- (BOOL)swipeUsingIOHIDEvent:(CGPoint)start
                          to:(CGPoint)end
                    duration:(NSTimeInterval)duration {
  int steps = MAX((int)(duration * 60), 10); // 60fps or min 10 steps
  NSTimeInterval stepDuration = duration / steps;

  // Down
  [self sendIOHIDEventAtPoint:start type:1];
  usleep(10000);

  // Move
  for (int i = 1; i <= steps; i++) {
    CGFloat progress = (CGFloat)i / steps;
    CGPoint current = CGPointMake(start.x + (end.x - start.x) * progress,
                                  start.y + (end.y - start.y) * progress);
    [self sendIOHIDEventAtPoint:current type:2];
    usleep((useconds_t)(stepDuration * 1000000));
  }

  // Up
  [self sendIOHIDEventAtPoint:end type:3];
  return YES;
}

- (void)sendIOHIDEventAtPoint:(CGPoint)point type:(int)type {
  // type: 1=Down, 2=Move, 3=Up
  uint64_t timestamp = mach_absolute_time();

  Boolean isRange = (type != 3);
  Boolean isTouch = (type != 3);

  CGRect screenBounds = [[UIScreen mainScreen] bounds];
  CGFloat x = point.x * screenBounds.size.width;
  CGFloat y = point.y * screenBounds.size.height;

  // Call with reversed engineered signature
  IOHIDEventRef event = _IOHIDEventCreateDigitizerEvent(
      kCFAllocatorDefault, timestamp,
      2,                   // kIOHIDDigitizerTransducerTypeFinger
      0,                   // index
      0,                   // identity
      0,                   // eventMask
      0,                   // buttonMask
      x, y, 0.0, 0.5, 0.0, // floats: x, y, z, tip, barrel
      isRange, isTouch,    // bools
      0                    // options
  );

  if (event) {
    _IOHIDEventSetSenderID(event, _digitizerServiceID);

    // Set HandID/TransducerID
    if (_IOHIDEventSetIntegerValue) {
      _IOHIDEventSetIntegerValue(event, 0x4,
                                 1); // kIOHIDEventFieldDigitizerIndex
      _IOHIDEventSetIntegerValue(event, 0x3, 1); // Identity
      _IOHIDEventSetIntegerValue(event, 0xb, 1); // IsTouch
    }

    _IOHIDEventSystemClientDispatchEvent(_client, event);
    CFRelease(event);
  }
}

- (void)dealloc {
  if (_ioKitHandle)
    dlclose(_ioKitHandle);
  if (_gsHandle)
    dlclose(_gsHandle);
}

@end
