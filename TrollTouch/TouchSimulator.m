#import "TouchSimulator.h"
#import <dlfcn.h>
#import <mach/mach_time.h>

// IOHIDEvent Private API Definitions

typedef struct __IOHIDEvent *IOHIDEventRef;
typedef struct __IOHIDEventSystemClient *IOHIDEventSystemClientRef;

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

  IOHIDEventSystemClientRef _client;
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

  if (_IOHIDEventSystemClientCreate) {
    _client = _IOHIDEventSystemClientCreate(kCFAllocatorDefault);
    NSLog(@"[TouchSimulator] ✅ IOHIDEvent system loaded");
  }
}

- (void)sendTouchEvent:(int)type x:(float)x y:(float)y {
  if (!_client || !_IOHIDEventCreateDigitizerEvent)
    return;

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
      x, y, 0, 0.5, 0, 0, 0, 0); // Pressure = 0.5

  if (event) {
    _IOHIDEventSetSenderID(event, 0x000000010000027F);

    // Critical: manually set fields to ensure properties are correct
    if (_IOHIDEventSetIntegerValue) {
      _IOHIDEventSetIntegerValue(event, kIOHIDEventFieldDigitizerTouch,
                                 isTouch);
      _IOHIDEventSetIntegerValue(event, kIOHIDEventFieldDigitizerRange,
                                 1); // Range is always 1 while active
      _IOHIDEventSetIntegerValue(event, kIOHIDEventFieldDigitizerIndex, 0);
      _IOHIDEventSetIntegerValue(event, kIOHIDEventFieldDigitizerIdentity, 2);
      _IOHIDEventSetIntegerValue(event, kIOHIDEventFieldDigitizerEventMask,
                                 eventMask);
    }

    _IOHIDEventSystemClientDispatchEvent(_client, event);
    CFRelease(event); // Cleanup
  }
}

- (void)tapAtPoint:(CGPoint)point {
  NSLog(@"[TouchSimulator] Tap at %.3f, %.3f", point.x, point.y);
  [self sendTouchEvent:1 x:point.x y:point.y]; // Down
  usleep(50000);                               // 50ms
  [self sendTouchEvent:3
                     x:point.x
                     y:point.y]; // Up (using 3 as 'Up' logic in my helper)
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
