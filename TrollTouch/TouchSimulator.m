#import "TouchSimulator.h"
#import <dlfcn.h>
#import <mach/mach_time.h>

// IOHIDEvent Private API Definitions

typedef struct __IOHIDEvent *IOHIDEventRef;
typedef struct __IOHIDEventSystemClient *IOHIDEventSystemClientRef;

// Event Types
#define kIOHIDEventTypeDigitizer 11

// Event Fields (Accessors)
#define kIOHIDEventFieldDigitizerTouch 0
#define kIOHIDEventFieldDigitizerIndex 3
#define kIOHIDEventFieldDigitizerIdentity 4
#define kIOHIDEventFieldDigitizerEventMask 7

// Detailed Digitizer Event constants
// kIOHIDDigitizerEventRange | kIOHIDDigitizerEventTouch |
// kIOHIDDigitizerEventIdentity
#define kDigitizerFingerDown (0x00000001 | 0x00000002 | 0x00000020)
#define kDigitizerFingerMove                                                   \
  (0x00000001 | 0x00000002 | 0x00000020 | 0x00000004) // + Position
#define kDigitizerFingerUp                                                     \
  (0x00000001 | 0x00000002 | 0x00000020 | 0x00000002) // + Range/Touch off

// Private Function Types
typedef IOHIDEventSystemClientRef (*IOHIDEventSystemClientCreateFunc)(
    CFAllocatorRef);
typedef IOHIDEventRef (*IOHIDEventCreateDigitizerEventFunc)(
    CFAllocatorRef, uint64_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t,
    float, float, float, float, float, uint32_t, uint32_t, uint32_t);
typedef void (*IOHIDEventSetSenderIDFunc)(IOHIDEventRef, uint64_t);
typedef void (*IOHIDEventSystemClientDispatchEventFunc)(
    IOHIDEventSystemClientRef, IOHIDEventRef);
typedef void (*IOHIDEventSetIntegerValueFunc)(IOHIDEventRef, uint32_t, int64_t);

@implementation TouchSimulator {
  void *_ioKitHandle;
  IOHIDEventSystemClientCreateFunc _IOHIDEventSystemClientCreate;
  IOHIDEventCreateDigitizerEventFunc _IOHIDEventCreateDigitizerEvent;
  IOHIDEventSetSenderIDFunc _IOHIDEventSetSenderID;
  IOHIDEventSystemClientDispatchEventFunc _IOHIDEventSystemClientDispatchEvent;
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
  // Load IOKit framework dynamically
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

  if (_IOHIDEventSystemClientCreate) {
    _client = _IOHIDEventSystemClientCreate(kCFAllocatorDefault);
    NSLog(@"[TouchSimulator] ✅ IOHIDEvent system loaded");
  }
}

- (void)sendTouchEvent:(int)type x:(float)x y:(float)y {
  if (!_client || !_IOHIDEventCreateDigitizerEvent)
    return;

  // Create timestamp
  uint64_t timestamp = mach_absolute_time();

  // Flags based on action
  uint32_t eventMask = 0;
  uint32_t touchType = 0; // 2 for finger usually?

  // Standard IOHID digitizer flags
  // 1(Range) | 2(Touch)
  // Down: 1|2 = 3
  // Move: 1|2 = 3
  // Up: 0 = 0 (Actually just Range 1, Touch 0)

  // Let's use simplified flags known to work
  // 1 = Down (Touch + Range)
  // 2 = Up (Range only or None)
  // 4 = Move

  uint32_t flags = 0;
  if (type == 1) { // Down
    flags = kDigitizerFingerDown;
    eventMask = 0x1;      // Down
  } else if (type == 2) { // Move
    flags = kDigitizerFingerMove;
    eventMask = 0x4; // Move
  } else {           // Up
    flags = kDigitizerFingerUp;
    eventMask = 0x2; // Up
  }

  // Normally x,y are 0.0-1.0
  // But check if we need absolute? APIs usually take 0.0-1.0

  // Parameters map:
  // allocator, timestamp, type(kIOHIDEventTypeDigitizer), index(0),
  // identity(2), eventMask, buttonMask, x, y, z, tipPressure, barrelPressure,
  // range, touch, options IOHIDEventCreateDigitizerEvent(alloc, time,
  // kIOHIDEventTypeDigitizer, TRANS_ID, IDENTITY, MASK, BUTTON, x, y, 0, 0, 0,
  // 0, 0, 0)

  // Re-verifying signature for CreateDigitizerEvent... it varies by iOS
  // version. iOS 14+ usually simpler. Let's try the standard known payload.

  // Using a simpler approach: IOHIDEventCreateDigitizerEvent
  // (allocator, timestamp, transType, identity, eventMask, buttonMask, x, y, z,
  // pressure, twist, isRange, isTouch, options)

  // Actually, let's use the widely used "SimulateTouch" implementation
  // reference type: 1=Touch, 2=Untouch, 3=Move

  uint32_t handEventMask = 0;
  uint32_t handTouchStr = 0;

  if (type == 1) {                      // Down
    handEventMask = 0x01 | 0x02 | 0x04; // Range | Touch | Position
    handTouchStr = 1;
  } else if (type == 2) { // Move
    handEventMask = 0x04; // Position only update
    handTouchStr = 1;
  } else {                       // Up
    handEventMask = 0x01 | 0x02; // Range | Touch (state change)
    handTouchStr = 0;            // Lift
  }

  IOHIDEventRef event = _IOHIDEventCreateDigitizerEvent(
      kCFAllocatorDefault, timestamp, kIOHIDEventTypeDigitizer,
      0, // index
      0, // identity
      handEventMask,
      0,                     // button mask
      x, y, 0, 0, 0, 0, 0, 0 // x,y,z...
  );

  // Fix up fields manually closer to real iOS events if needed
  // But let's try dispatching this.

  if (event) {
    _IOHIDEventSetSenderID(event, 0x0000000123456789); // Fake sender ID
    _IOHIDEventSystemClientDispatchEvent(_client, event);
    CFRelease(event);
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
