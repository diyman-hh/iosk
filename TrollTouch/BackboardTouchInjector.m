//
//  BackboardTouchInjector.m
//  TrollTouch
//
//  System-level touch injection using BackboardServices
//  This is the REAL solution for cross-app touch injection
//

#import "BackboardTouchInjector.h"
#import "BackboardServices.h"
#import "IOKit_Private.h"
#import <UIKit/UIKit.h>
#import <dlfcn.h>
#import <mach/mach_time.h>

// Function pointers
typedef void (*BKSendHIDEventFunc)(IOHIDEventRef event);
typedef mach_port_t (*BKSHIDServicesCopyEventPortFunc)(void);

@implementation BackboardTouchInjector {
  BKSendHIDEventFunc _BKSendHIDEvent;
  BKSHIDServicesCopyEventPortFunc _BKSHIDServicesCopyEventPort;
  mach_port_t _eventPort;
  BOOL _initialized;
}

+ (instancetype)sharedInjector {
  static BackboardTouchInjector *instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[self alloc] init];
  });
  return instance;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _initialized = NO;
  }
  return self;
}

- (BOOL)initialize {
  if (_initialized) {
    return YES;
  }

  NSLog(@"[Backboard] Initializing system-level touch injection...");

  // Load BackboardServices framework
  void *handle = dlopen("/System/Library/PrivateFrameworks/"
                        "BackboardServices.framework/BackboardServices",
                        RTLD_LAZY);
  if (!handle) {
    NSLog(@"[Backboard] ERROR: Failed to load BackboardServices");
    return NO;
  }

  // Get function pointers
  _BKSendHIDEvent = (BKSendHIDEventFunc)dlsym(handle, "BKSendHIDEvent");
  _BKSHIDServicesCopyEventPort = (BKSHIDServicesCopyEventPortFunc)dlsym(
      handle, "BKSHIDServicesCopyEventPort");

  if (!_BKSendHIDEvent) {
    NSLog(@"[Backboard] ERROR: BKSendHIDEvent not found");
    return NO;
  }

  if (_BKSHIDServicesCopyEventPort) {
    _eventPort = _BKSHIDServicesCopyEventPort();
    NSLog(@"[Backboard] Event port: %d", _eventPort);
  }

  _initialized = YES;
  NSLog(@"[Backboard] ✅ Initialized successfully!");
  NSLog(@"[Backboard] BKSendHIDEvent: %p", _BKSendHIDEvent);

  return YES;
}

- (void)tapAtX:(float)x y:(float)y {
  if (![self initialize]) {
    NSLog(@"[Backboard] ERROR: Not initialized");
    return;
  }

  NSLog(@"[Backboard] Tap at (%.2f, %.2f)", x, y);

  // Send touch down
  [self sendTouchEventAtX:x y:y phase:1]; // kIOHIDDigitizerEventTouch
  usleep(50000);                          // 50ms

  // Send touch up
  [self sendTouchEventAtX:x
                        y:y
                    phase:3]; // kIOHIDDigitizerEventRange |
                              // kIOHIDDigitizerEventTouch
}

- (void)swipeFromX:(float)x1
                 y:(float)y1
               toX:(float)x2
                 y:(float)y2
          duration:(float)duration {
  if (![self initialize]) {
    NSLog(@"[Backboard] ERROR: Not initialized");
    return;
  }

  NSLog(@"[Backboard] Swipe from (%.2f, %.2f) to (%.2f, %.2f) over %.2fs", x1,
        y1, x2, y2, duration);

  // Touch down
  [self sendTouchEventAtX:x1 y:y1 phase:1];
  usleep(10000);

  // Move in steps
  int steps = (int)(duration * 60); // 60 FPS
  if (steps < 10)
    steps = 10;

  for (int i = 1; i <= steps; i++) {
    float t = (float)i / steps;
    float x = x1 + (x2 - x1) * t;
    float y = y1 + (y2 - y1) * t;

    [self sendTouchEventAtX:x y:y phase:2]; // kIOHIDDigitizerEventPosition
    usleep((useconds_t)(duration * 1000000 / steps));
  }

  // Touch up
  [self sendTouchEventAtX:x2 y:y2 phase:3];
}

- (void)sendTouchEventAtX:(float)x y:(float)y phase:(int)phase {
  // Get screen dimensions
  CGRect screenBounds = [[UIScreen mainScreen] bounds];
  CGFloat scale = [[UIScreen mainScreen] scale];

  // Convert normalized to absolute coordinates
  float absX = x * screenBounds.size.width * scale;
  float absY = y * screenBounds.size.height * scale;

  // Create digitizer event
  uint64_t machTime = mach_absolute_time();
  AbsoluteTime timestamp = *(AbsoluteTime *)&machTime;

  uint32_t eventMask = 0;
  switch (phase) {
  case 1: // Touch down
    eventMask = kIOHIDDigitizerEventRange | kIOHIDDigitizerEventTouch |
                kIOHIDDigitizerEventIdentity;
    break;
  case 2: // Move
    eventMask = kIOHIDDigitizerEventPosition;
    break;
  case 3: // Touch up
    eventMask = kIOHIDDigitizerEventRange | kIOHIDDigitizerEventTouch;
    break;
  }

  IOHIDEventRef event = IOHIDEventCreateDigitizerFingerEvent(
      kCFAllocatorDefault, timestamp,
      0, // index
      1, // identity
      eventMask,
      absX,                   // x
      absY,                   // y
      0.0,                    // z
      phase == 3 ? 0.0 : 1.0, // tip pressure (0 for up, 1 for down/move)
      0.0,                    // twist
      phase != 3              // range (true for down/move, false for up)
  );

  if (event) {
    // Set additional fields
    IOHIDEventSetIntegerValue(event,
                              kIOHIDEventFieldDigitizerIsDisplayIntegrated, 1);

    // Send the event via BackboardServices
    _BKSendHIDEvent(event);

    CFRelease(event);

    NSLog(@"[Backboard] ✅ Sent event: phase=%d at (%.0f, %.0f)", phase, absX,
          absY);
  } else {
    NSLog(@"[Backboard] ERROR: Failed to create event");
  }
}

@end
