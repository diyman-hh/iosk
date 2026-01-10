//
//  TouchInjector.m
//  TrollTouchAgent
//

#import "TouchInjector.h"
#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>
#import <dlfcn.h>
#import <mach/mach.h>

// IOHIDEvent Types
typedef struct __IOHIDEvent *IOHIDEventRef;
typedef struct __IOHIDEventSystemClient *IOHIDEventSystemClientRef;
typedef struct __IOHIDServiceClient *IOHIDServiceClientRef;

// Function Pointer Types
typedef IOHIDEventSystemClientRef (*IOHIDEventSystemClientCreateFunc)(
    CFAllocatorRef);
typedef IOHIDEventRef (*IOHIDEventCreateDigitizerEventFunc)(
    CFAllocatorRef, uint64_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t,
    CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, Boolean, Boolean, uint32_t);
typedef void (*IOHIDEventSetSenderIDFunc)(IOHIDEventRef, uint64_t);
typedef void (*IOHIDEventSystemClientDispatchEventFunc)(
    IOHIDEventSystemClientRef, IOHIDEventRef);
typedef void (*IOHIDEventSetIntegerValueFunc)(IOHIDEventRef, uint32_t, int32_t);
typedef void (*IOHIDEventSystemClientSetMatchingFunc)(IOHIDEventSystemClientRef,
                                                      CFDictionaryRef);
typedef CFArrayRef (*IOHIDEventSystemClientCopyServicesFunc)(
    IOHIDEventSystemClientRef);
typedef uint64_t (*IOHIDServiceClientGetRegistryIDFunc)(IOHIDServiceClientRef);
typedef CFTypeRef (*IOHIDServiceClientCopyPropertyFunc)(IOHIDServiceClientRef,
                                                        CFStringRef);

// GraphicsServices Types
typedef void (*GSSendSysEventFunc)(const void *);

// HID Usage Tables
#define kHIDPage_Digitizer 0x0D
#define kHIDUsage_Dig_TouchScreen 0x04

// Event Masks
#define kIOHIDDigitizerEventRange (1 << 0)
#define kIOHIDDigitizerEventTouch (1 << 1)
#define kIOHIDDigitizerEventPosition (1 << 2)
#define kIOHIDDigitizerEventIdentity (1 << 5)

@interface TouchInjector () {
  void *_ioKitHandle;
  IOHIDEventSystemClientRef _client;
  uint64_t _digitizerServiceID;

  IOHIDEventSystemClientCreateFunc _IOHIDEventSystemClientCreate;
  IOHIDEventCreateDigitizerEventFunc _IOHIDEventCreateDigitizerEvent;
  IOHIDEventSetSenderIDFunc _IOHIDEventSetSenderID;
  IOHIDEventSystemClientDispatchEventFunc _IOHIDEventSystemClientDispatchEvent;
  IOHIDEventSetIntegerValueFunc _IOHIDEventSetIntegerValue;
  IOHIDEventSystemClientSetMatchingFunc _IOHIDEventSystemClientSetMatching;
  IOHIDEventSystemClientCopyServicesFunc _IOHIDEventSystemClientCopyServices;
  IOHIDServiceClientGetRegistryIDFunc _IOHIDServiceClientGetRegistryID;
  IOHIDServiceClientCopyPropertyFunc _IOHIDServiceClientCopyProperty;

  void *_gsHandle;
  GSSendSysEventFunc _GSSendSysEvent;
}

@property(nonatomic, copy) NSString *currentMethod;
@property(nonatomic, strong) NSMutableDictionary *apiStatus;

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
    self.apiStatus = [NSMutableDictionary dictionary];
    [self initializeIOHIDEvent];
    [self initializeGraphicsServices];
  }
  return self;
}

#pragma mark - Status Properties

- (BOOL)iohidLoaded {
  return (_client != NULL && _digitizerServiceID != 0);
}

- (BOOL)gsLoaded {
  return (_GSSendSysEvent != NULL);
}

- (NSString *)statusString {
  NSMutableString *status = [NSMutableString string];

  [status appendFormat:@"=== IOKit Framework ===\n"];
  [status appendFormat:@"IOKit.framework: %@\n", _ioKitHandle ? @"✅" : @"❌"];

  [status appendFormat:@"\n=== Core APIs ===\n"];
  [status appendFormat:@"ClientCreate: %@\n",
                       _IOHIDEventSystemClientCreate ? @"✅" : @"❌"];
  [status appendFormat:@"CreateDigitizer: %@\n",
                       _IOHIDEventCreateDigitizerEvent ? @"✅" : @"❌"];
  [status appendFormat:@"SetSenderID: %@\n",
                       _IOHIDEventSetSenderID ? @"✅" : @"❌"];
  [status appendFormat:@"DispatchEvent: %@\n",
                       _IOHIDEventSystemClientDispatchEvent ? @"✅" : @"❌"];
  [status appendFormat:@"SetIntegerValue: %@\n",
                       _IOHIDEventSetIntegerValue ? @"✅" : @"❌"];

  [status appendFormat:@"\n=== Discovery APIs ===\n"];
  [status appendFormat:@"SetMatching: %@\n",
                       _IOHIDEventSystemClientSetMatching ? @"✅" : @"❌"];
  [status appendFormat:@"CopyServices: %@\n",
                       _IOHIDEventSystemClientCopyServices ? @"✅" : @"❌"];
  [status appendFormat:@"GetRegistryID: %@\n",
                       _IOHIDServiceClientGetRegistryID ? @"✅" : @"❌"];
  [status appendFormat:@"CopyProperty: %@\n",
                       _IOHIDServiceClientCopyProperty ? @"✅" : @"❌"];

  [status appendFormat:@"\n=== Runtime ===\n"];
  [status appendFormat:@"Client: %@\n", _client ? @"✅" : @"❌"];
  [status appendFormat:@"ServiceID: 0x%llX\n", _digitizerServiceID];

  [status appendFormat:@"\n=== GraphicsServices ===\n"];
  [status appendFormat:@"GS.framework: %@\n", _gsHandle ? @"✅" : @"❌"];
  [status
      appendFormat:@"GSSendSysEvent: %@\n", _GSSendSysEvent ? @"✅" : @"❌"];

  return status;
}

#pragma mark - Initialization

- (void)initializeIOHIDEvent {
  NSLog(@"[TouchInjector] 🔧 Loading IOKit.framework...");

  _ioKitHandle =
      dlopen("/System/Library/Frameworks/IOKit.framework/IOKit", RTLD_LAZY);
  if (!_ioKitHandle) {
    NSLog(@"[TouchInjector] ❌ Failed to load IOKit: %s", dlerror());
    return;
  }
  NSLog(@"[TouchInjector] ✅ IOKit.framework loaded");

  // Load Core Functions
  NSLog(@"[TouchInjector] 📦 Loading Core APIs...");
  _IOHIDEventSystemClientCreate = (IOHIDEventSystemClientCreateFunc)dlsym(
      _ioKitHandle, "IOHIDEventSystemClientCreate");
  NSLog(@"[TouchInjector]   ClientCreate: %@",
        _IOHIDEventSystemClientCreate ? @"✅" : @"❌");

  _IOHIDEventCreateDigitizerEvent = (IOHIDEventCreateDigitizerEventFunc)dlsym(
      _ioKitHandle, "IOHIDEventCreateDigitizerEvent");
  NSLog(@"[TouchInjector]   CreateDigitizerEvent: %@",
        _IOHIDEventCreateDigitizerEvent ? @"✅" : @"❌");

  _IOHIDEventSetSenderID =
      (IOHIDEventSetSenderIDFunc)dlsym(_ioKitHandle, "IOHIDEventSetSenderID");
  NSLog(@"[TouchInjector]   SetSenderID: %@",
        _IOHIDEventSetSenderID ? @"✅" : @"❌");

  _IOHIDEventSystemClientDispatchEvent =
      (IOHIDEventSystemClientDispatchEventFunc)dlsym(
          _ioKitHandle, "IOHIDEventSystemClientDispatchEvent");
  NSLog(@"[TouchInjector]   DispatchEvent: %@",
        _IOHIDEventSystemClientDispatchEvent ? @"✅" : @"❌");

  _IOHIDEventSetIntegerValue = (IOHIDEventSetIntegerValueFunc)dlsym(
      _ioKitHandle, "IOHIDEventSetIntegerValue");
  NSLog(@"[TouchInjector]   SetIntegerValue: %@",
        _IOHIDEventSetIntegerValue ? @"✅" : @"❌");

  // Load Discovery Functions
  NSLog(@"[TouchInjector] 🔍 Loading Discovery APIs...");
  _IOHIDEventSystemClientSetMatching =
      (IOHIDEventSystemClientSetMatchingFunc)dlsym(
          _ioKitHandle, "IOHIDEventSystemClientSetMatching");
  NSLog(@"[TouchInjector]   SetMatching: %@",
        _IOHIDEventSystemClientSetMatching ? @"✅" : @"❌");

  _IOHIDEventSystemClientCopyServices =
      (IOHIDEventSystemClientCopyServicesFunc)dlsym(
          _ioKitHandle, "IOHIDEventSystemClientCopyServices");
  NSLog(@"[TouchInjector]   CopyServices: %@",
        _IOHIDEventSystemClientCopyServices ? @"✅" : @"❌");

  _IOHIDServiceClientGetRegistryID = (IOHIDServiceClientGetRegistryIDFunc)dlsym(
      _ioKitHandle, "IOHIDServiceClientGetRegistryID");
  NSLog(@"[TouchInjector]   GetRegistryID: %@",
        _IOHIDServiceClientGetRegistryID ? @"✅" : @"❌");

  _IOHIDServiceClientCopyProperty = (IOHIDServiceClientCopyPropertyFunc)dlsym(
      _ioKitHandle, "IOHIDServiceClientCopyProperty");
  NSLog(@"[TouchInjector]   CopyProperty: %@",
        _IOHIDServiceClientCopyProperty ? @"✅" : @"❌");

  // Create Client
  if (_IOHIDEventSystemClientCreate) {
    NSLog(@"[TouchInjector] 🏗️ Creating IOHIDEventSystemClient...");
    _client = _IOHIDEventSystemClientCreate(kCFAllocatorDefault);
    if (_client) {
      NSLog(@"[TouchInjector] ✅ Client created successfully");
      [self findDigitizerService];

      if (_digitizerServiceID == 0) {
        _digitizerServiceID = 0x8000000817319372;
        NSLog(@"[TouchInjector] ⚠️ Using fallback ServiceID: 0x%llX",
              _digitizerServiceID);
        self.currentMethod = @"IOHIDEvent (Fallback)";
      }
    } else {
      NSLog(@"[TouchInjector] ❌ Failed to create client");
    }
  }
}

- (void)findDigitizerService {
  if (!_IOHIDEventSystemClientSetMatching ||
      !_IOHIDEventSystemClientCopyServices) {
    NSLog(@"[TouchInjector] ⚠️ Discovery APIs not available");
    return;
  }

  NSLog(@"[TouchInjector] 🔎 Searching for digitizer service...");
  NSDictionary *matching = @{
    @"PrimaryUsagePage" : @(kHIDPage_Digitizer),
    @"PrimaryUsage" : @(kHIDUsage_Dig_TouchScreen)
  };

  _IOHIDEventSystemClientSetMatching(_client,
                                     (__bridge CFDictionaryRef)matching);

  CFArrayRef services = _IOHIDEventSystemClientCopyServices(_client);
  if (services) {
    CFIndex count = CFArrayGetCount(services);
    NSLog(@"[TouchInjector] 📋 Found %ld service(s)", count);

    if (count > 0) {
      IOHIDServiceClientRef service =
          (IOHIDServiceClientRef)CFArrayGetValueAtIndex(services, 0);

      if (_IOHIDServiceClientGetRegistryID) {
        _digitizerServiceID = _IOHIDServiceClientGetRegistryID(service);
        NSLog(@"[TouchInjector] 🆔 GetRegistryID returned: 0x%llX",
              _digitizerServiceID);
      }

      if (_digitizerServiceID == 0 && _IOHIDServiceClientCopyProperty) {
        NSNumber *regID =
            (__bridge_transfer NSNumber *)_IOHIDServiceClientCopyProperty(
                service, CFSTR("RegistryID"));
        if (regID) {
          _digitizerServiceID = [regID unsignedLongLongValue];
          NSLog(@"[TouchInjector] 🆔 CopyProperty returned: 0x%llX",
                _digitizerServiceID);
        }
      }

      if (_digitizerServiceID != 0) {
        NSString *productName = @"Unknown";
        if (_IOHIDServiceClientCopyProperty) {
          NSString *name =
              (__bridge_transfer NSString *)_IOHIDServiceClientCopyProperty(
                  service, CFSTR("Product"));
          if (name)
            productName = name;
        }

        NSLog(@"[TouchInjector] ✅ Service found: %@ (0x%llX)", productName,
              _digitizerServiceID);
        self.currentMethod = @"IOHIDEvent";
      } else {
        NSLog(@"[TouchInjector] ⚠️ Service found but ID is 0");
      }
    } else {
      NSLog(@"[TouchInjector] ⚠️ No matching services");
    }
    CFRelease(services);
  } else {
    NSLog(@"[TouchInjector] ❌ CopyServices returned NULL");
  }
}

- (void)initializeGraphicsServices {
  NSLog(@"[TouchInjector] 🔧 Loading GraphicsServices.framework...");
  _gsHandle = dlopen("/System/Library/PrivateFrameworks/"
                     "GraphicsServices.framework/GraphicsServices",
                     RTLD_LAZY);
  if (!_gsHandle) {
    NSLog(@"[TouchInjector] ⚠️ GraphicsServices not available");
    return;
  }
  NSLog(@"[TouchInjector] ✅ GraphicsServices.framework loaded");

  _GSSendSysEvent = (GSSendSysEventFunc)dlsym(_gsHandle, "GSSendSysEvent");
  NSLog(@"[TouchInjector]   GSSendSysEvent: %@",
        _GSSendSysEvent ? @"✅" : @"❌");
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
  [self sendIOHIDEventAtPoint:point type:1];
  usleep(60000);
  [self sendIOHIDEventAtPoint:point type:3];
  return YES;
}

- (BOOL)swipeUsingIOHIDEvent:(CGPoint)start
                          to:(CGPoint)end
                    duration:(NSTimeInterval)duration {
  int steps = MAX((int)(duration * 60), 10);
  NSTimeInterval stepDuration = duration / steps;

  [self sendIOHIDEventAtPoint:start type:1];
  usleep(10000);

  for (int i = 1; i <= steps; i++) {
    CGFloat progress = (CGFloat)i / steps;
    CGPoint current = CGPointMake(start.x + (end.x - start.x) * progress,
                                  start.y + (end.y - start.y) * progress);
    [self sendIOHIDEventAtPoint:current type:2];
    usleep((useconds_t)(stepDuration * 1000000));
  }

  [self sendIOHIDEventAtPoint:end type:3];
  return YES;
}

- (void)sendIOHIDEventAtPoint:(CGPoint)point type:(int)type {
  uint64_t timestamp = mach_absolute_time();
  Boolean isRange = (type != 3);
  Boolean isTouch = (type != 3);

  uint32_t eventMask = kIOHIDDigitizerEventRange | kIOHIDDigitizerEventTouch |
                       kIOHIDDigitizerEventPosition |
                       kIOHIDDigitizerEventIdentity;

  CGRect screenBounds = [[UIScreen mainScreen] bounds];
  CGFloat x = point.x * screenBounds.size.width;
  CGFloat y = point.y * screenBounds.size.height;

  uint32_t handId = 2;

  IOHIDEventRef event =
      _IOHIDEventCreateDigitizerEvent(kCFAllocatorDefault, timestamp,
                                      2,      // Finger
                                      0,      // index
                                      handId, // identity
                                      eventMask,
                                      0, // buttonMask
                                      x, y, 0.0, 0.0, 0.0, isRange, isTouch, 0);

  if (event) {
    _IOHIDEventSetSenderID(event, _digitizerServiceID);

    if (_IOHIDEventSetIntegerValue) {
      _IOHIDEventSetIntegerValue(event, 0x4, 0);
      _IOHIDEventSetIntegerValue(event, 0x3, handId);
      _IOHIDEventSetIntegerValue(event, 0xb, isTouch ? 1 : 0);
      _IOHIDEventSetIntegerValue(event, 0xa, isRange ? 1 : 0);
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
