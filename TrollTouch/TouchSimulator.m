#import "TouchSimulator.h"
#import <CoreFoundation/CoreFoundation.h>
#import <dlfcn.h>
#import <mach/mach_time.h>


// IOHIDEvent Private API Definitions

typedef struct __IOHIDEvent *IOHIDEventRef;
typedef struct __IOHIDEventSystemClient *IOHIDEventSystemClientRef;
typedef struct __IOHIDServiceClient *IOHIDServiceClientRef;

// Event Types
#define kIOHIDEventTypeDigitizer 11

// Function pointers
typedef IOHIDEventSystemClientRef (*IOHIDEventSystemClientCreateFunc)(
    CFAllocatorRef);
typedef IOHIDEventRef (*IOHIDEventCreateDigitizerEventFunc)(
    CFAllocatorRef, uint64_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t,
    float, float, float, float, float, uint32_t, uint32_t, uint32_t);
typedef void (*IOHIDEventSetSenderIDFunc)(IOHIDEventRef, uint64_t);
typedef void (*IOHIDEventSystemClientDispatchEventFunc)(
    IOHIDEventSystemClientRef, IOHIDEventRef);
typedef void (*IOHIDEventSetIntegerValueFunc)(IOHIDEventRef, uint32_t, int64_t);
typedef void (*IOHIDEventSystemClientSetMatchingFunc)(IOHIDEventSystemClientRef,
                                                      CFDictionaryRef);
typedef CFArrayRef (*IOHIDEventSystemClientCopyServicesFunc)(
    IOHIDEventSystemClientRef);
typedef CFTypeRef (*IOHIDServiceClientCopyPropertyFunc)(IOHIDServiceClientRef,
                                                        CFStringRef);
typedef uint64_t (*IOHIDServiceClientGetRegistryIDFunc)(IOHIDServiceClientRef);

// Private IOHIDEvent definitions (Correct usage page shifted values)
#define kIOHIDEventFieldDigitizerX 720896
#define kIOHIDEventFieldDigitizerY 720897
#define kIOHIDEventFieldDigitizerEventMask 720903
#define kIOHIDEventFieldDigitizerRange 720904
#define kIOHIDEventFieldDigitizerTouch 720905
#define kIOHIDEventFieldDigitizerIndex 720901
#define kIOHIDEventFieldDigitizerIdentity 720902

@implementation TouchSimulator {
  void *_ioKitHandle;
  IOHIDEventSystemClientCreateFunc _IOHIDEventSystemClientCreate;
  IOHIDEventCreateDigitizerEventFunc _IOHIDEventCreateDigitizerEvent;
  IOHIDEventSetSenderIDFunc _IOHIDEventSetSenderID;
  IOHIDEventSystemClientDispatchEventFunc _IOHIDEventSystemClientDispatchEvent;
  IOHIDEventSetIntegerValueFunc _IOHIDEventSetIntegerValue;
  IOHIDEventSystemClientSetMatchingFunc _IOHIDEventSystemClientSetMatching;

  IOHIDEventSystemClientCopyServicesFunc _IOHIDEventSystemClientCopyServices;
  IOHIDServiceClientCopyPropertyFunc _IOHIDServiceClientCopyProperty;
  IOHIDServiceClientGetRegistryIDFunc _IOHIDServiceClientGetRegistryID;

  IOHIDEventSystemClientRef _client;
  uint64_t _digitizerServiceID;
}

+ (instancetype)sharedSimulator {
  static TouchSimulator *shared = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    shared = [[TouchSimulator alloc] init];
  });
  return shared;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _digitizerServiceID = 0;
    [self loadIOKit];
  }
  return self;
}

- (void)loadIOKit {
  _ioKitHandle =
      dlopen("/System/Library/Frameworks/IOKit.framework/IOKit", RTLD_LAZY);
  if (!_ioKitHandle) {
    NSLog(@"[TouchSimulator] ❌ Failed to load IOKit");
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
  _IOHIDEventSystemClientSetMatching =
      (IOHIDEventSystemClientSetMatchingFunc)dlsym(
          _ioKitHandle, "IOHIDEventSystemClientSetMatching");

  _IOHIDEventSystemClientCopyServices =
      (IOHIDEventSystemClientCopyServicesFunc)dlsym(
          _ioKitHandle, "IOHIDEventSystemClientCopyServices");
  _IOHIDServiceClientCopyProperty = (IOHIDServiceClientCopyPropertyFunc)dlsym(
      _ioKitHandle, "IOHIDServiceClientCopyProperty");
  _IOHIDServiceClientGetRegistryID = (IOHIDServiceClientGetRegistryIDFunc)dlsym(
      _ioKitHandle, "IOHIDServiceClientGetRegistryID");

  if (_IOHIDEventSystemClientCreate) {
    _client = _IOHIDEventSystemClientCreate(kCFAllocatorDefault);

    // 1. Activate Client with Match All
    if (_IOHIDEventSystemClientSetMatching) {
      _IOHIDEventSystemClientSetMatching(_client, NULL);
    }

    // 2. Find Digitizer Service
    if (_IOHIDEventSystemClientCopyServices &&
        _IOHIDServiceClientCopyProperty && _IOHIDServiceClientGetRegistryID) {
      CFArrayRef services = _IOHIDEventSystemClientCopyServices(_client);
      if (services) {
        NSLog(@"[TouchSimulator] Found %ld services",
              CFArrayGetCount(services));
        for (CFIndex i = 0; i < CFArrayGetCount(services); i++) {
          IOHIDServiceClientRef service =
              (IOHIDServiceClientRef)CFArrayGetValueAtIndex(services, i);
          CFNumberRef usagePageNum =
              (CFNumberRef)_IOHIDServiceClientCopyProperty(
                  service, CFSTR("PrimaryUsagePage"));
          CFNumberRef usageNum = (CFNumberRef)_IOHIDServiceClientCopyProperty(
              service, CFSTR("PrimaryUsage"));

          int usagePage = 0;
          int usage = 0;

          if (usagePageNum) {
            CFNumberGetValue(usagePageNum, kCFNumberIntType, &usagePage);
            CFRelease(usagePageNum);
          }
          if (usageNum) {
            CFNumberGetValue(usageNum, kCFNumberIntType, &usage);
            CFRelease(usageNum);
          }

          // Inspecting services
          // NSLog(@"[TouchSimulator] Service %ld: Page 0x%X Usage 0x%X", i,
          // usagePage, usage);

          // Look for Digitizer (0x0D) & Touch Screen (0x04)
          if (usagePage == 0x0D && usage == 0x04) {
            _digitizerServiceID = _IOHIDServiceClientGetRegistryID(service);
            NSLog(@"[TouchSimulator] ✅ Found Touch Screen Service! ID: 0x%llX",
                  _digitizerServiceID);
            break;
          }
        }
        CFRelease(services);
      }
    }

    if (_digitizerServiceID == 0) {
      NSLog(@"[TouchSimulator] ⚠️ Warning: No specific touch service found. "
            @"Using fallback ID.");
      _digitizerServiceID = 0x000000010000027F; // Fallback
    }

    NSLog(@"[TouchSimulator] ✅ IOHIDEvent system loaded. SenderID: 0x%llX",
          _digitizerServiceID);
  }
}

- (void)sendTouchEvent:(int)type x:(float)x y:(float)y {
  if (!_client || !_IOHIDEventCreateDigitizerEvent) {
    NSLog(@"[TouchSimulator] ❌ Error: Client not initialized");
    return;
  }

  uint64_t timestamp = mach_absolute_time();

  // Type: 1=Down, 2=Move, 3=Up
  // IOHIDEvent masks
  uint32_t eventMask = 0;
  int isTouch = 0;

  if (type == 1) {                  // Down
    eventMask = 0x01 | 0x02 | 0x04; // Range | Touch | Position
    isTouch = 1;
  } else if (type == 2) { // Move
    eventMask = 0x04;     // Position
    isTouch = 1;
  } else if (type == 3) {    // Up
    eventMask = 0x01 | 0x02; // Range | Touch
    isTouch = 0;
  }

  // Create base event
  IOHIDEventRef event = _IOHIDEventCreateDigitizerEvent(
      kCFAllocatorDefault, timestamp, kIOHIDEventTypeDigitizer,
      0, // index
      0, // identity
      eventMask,
      0,                         // button mask
      x, y, 0, 0.5, 0, 0, 0, 0); // Pressure = 0.5 (Fixed)

  if (event) {
    _IOHIDEventSetSenderID(event, _digitizerServiceID);

    // Critical: manually set fields to ensure properties are correct matching
    // WDA behavior
    if (_IOHIDEventSetIntegerValue) {
      _IOHIDEventSetIntegerValue(event, kIOHIDEventFieldDigitizerTouch,
                                 isTouch);
      _IOHIDEventSetIntegerValue(event, kIOHIDEventFieldDigitizerRange,
                                 1); // Range valid
      _IOHIDEventSetIntegerValue(event, kIOHIDEventFieldDigitizerIndex,
                                 0); // Finger index 0
      _IOHIDEventSetIntegerValue(event, kIOHIDEventFieldDigitizerIdentity,
                                 2); // Finger Identity 2
      _IOHIDEventSetIntegerValue(event, kIOHIDEventFieldDigitizerEventMask,
                                 eventMask);
    }

    _IOHIDEventSystemClientDispatchEvent(_client, event);
    CFRelease(event); // Cleanup
  } else {
    NSLog(@"[TouchSimulator] ❌ Failed to create event");
  }
}

- (void)tapAtPoint:(CGPoint)point {
  NSLog(@"[TouchSimulator] Tap at %.3f, %.3f", point.x, point.y);
  [self sendTouchEvent:1 x:point.x y:point.y]; // Down
  usleep(50000);                               // 50ms
  [self sendTouchEvent:3 x:point.x y:point.y]; // Up
}

- (void)swipeFrom:(CGPoint)start
               to:(CGPoint)end
         duration:(NSTimeInterval)duration {
  NSLog(@"[TouchSimulator] Swipe from %.3f, %.3f to %.3f, %.3f", start.x,
        start.y, end.x, end.y);

  [self sendTouchEvent:1 x:start.x y:start.y]; // Down
  usleep(10000);                               // 10ms hold

  int steps = (int)(duration * 60);
  if (steps < 5)
    steps = 5;

  for (int i = 0; i < steps; i++) {
    float t = (float)i / steps;
    float x = start.x + (end.x - start.x) * t;
    float y = start.y + (end.y - start.y) * t;

    [self sendTouchEvent:2 x:x y:y]; // Move
    usleep((useconds_t)(duration * 1000000 / steps));
  }

  [self sendTouchEvent:3 x:end.x y:end.y]; // Up
}

@end
