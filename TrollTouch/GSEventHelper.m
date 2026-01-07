//
//  GSEventHelper.m
//  TrollTouch
//
//  Low-level touch injection using GraphicsServices
//

#import "GSEventHelper.h"
#import "GSEvent.h"
#import <UIKit/UIKit.h>
#import <dlfcn.h>

// Function pointer types
typedef void (*GSSendEventFunc)(GSEventRef event, mach_port_t port);
typedef void (*GSSendSystemEventFunc)(GSEventRef event);
typedef mach_port_t (*GSGetPurpleSystemEventPortFunc)(void);

static GSSendEventFunc _GSSendEvent = NULL;
static GSSendSystemEventFunc _GSSendSystemEvent = NULL;
static GSGetPurpleSystemEventPortFunc _GSGetPurpleSystemEventPort = NULL;
static mach_port_t _systemPort = 0;

void initGSEventSystem(void) {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    void *handle = dlopen("/System/Library/PrivateFrameworks/"
                          "GraphicsServices.framework/GraphicsServices",
                          RTLD_LAZY);
    if (handle) {
      _GSSendEvent = (GSSendEventFunc)dlsym(handle, "GSSendEvent");
      _GSSendSystemEvent =
          (GSSendSystemEventFunc)dlsym(handle, "GSSendSystemEvent");
      _GSGetPurpleSystemEventPort = (GSGetPurpleSystemEventPortFunc)dlsym(
          handle, "GSGetPurpleSystemEventPort");

      if (_GSGetPurpleSystemEventPort) {
        _systemPort = _GSGetPurpleSystemEventPort();
        printf("[GSEvent] System port: %d\n", _systemPort);
      }

      printf("[GSEvent] Initialized: SendEvent=%p SendSystemEvent=%p\n",
             _GSSendEvent, _GSSendSystemEvent);
    } else {
      printf("[GSEvent] ERROR: Failed to load GraphicsServices\n");
    }
  });
}

void sendGSTouch(float x, float y, int phase) {
  initGSEventSystem();

  if (!_GSSendSystemEvent && !_GSSendEvent) {
    printf("[GSEvent] ERROR: No send function available\n");
    return;
  }

  // Get screen bounds for absolute coordinates
  CGRect screenBounds = [[UIScreen mainScreen] bounds];
  CGFloat scale = [[UIScreen mainScreen] scale];

  // Convert normalized to absolute pixels
  float absX = x * screenBounds.size.width * scale;
  float absY = y * screenBounds.size.height * scale;

  printf("[GSEvent] Touch phase=%d at (%.2f, %.2f) -> abs(%.0f, %.0f)\n", phase,
         x, y, absX, absY);

  // Create UITouch-based event (simpler approach for iOS 15)
  UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
  if (!keyWindow) {
    // Try to get any window
    NSArray *windows = [[UIApplication sharedApplication] windows];
    if (windows.count > 0) {
      keyWindow = windows[0];
    }
  }

  if (keyWindow) {
    CGPoint point =
        CGPointMake(x * screenBounds.size.width, y * screenBounds.size.height);

    // Use private API to simulate touch
    // This is a fallback - on iOS 15, we need to use a different approach
    printf("[GSEvent] Attempting touch at window coordinates: (%.0f, %.0f)\n",
           point.x, point.y);

    // Try to post event via UIApplication
    [[UIApplication sharedApplication]
        sendEvent:nil]; // Placeholder - needs proper UIEvent creation
  }
}

void performGSTouch(float x, float y) {
  sendGSTouch(x, y, 1); // Down
  usleep(50000);
  sendGSTouch(x, y, 6); // Up
}

void performGSSwipe(float x1, float y1, float x2, float y2, float duration) {
  sendGSTouch(x1, y1, 1); // Down
  usleep(10000);

  int steps = (int)(duration * 60);
  if (steps < 10)
    steps = 10;

  for (int i = 1; i <= steps; i++) {
    float t = (float)i / steps;
    float cx = x1 + (x2 - x1) * t;
    float cy = y1 + (y2 - y1) * t;
    sendGSTouch(cx, cy, 2); // Move
    usleep((useconds_t)(duration * 1000000 / steps));
  }

  sendGSTouch(x2, y2, 6); // Up
}
