//
//  TouchSimulator.c
//  TrollTouch
//

#include "TouchSimulator.h"
#include "IOKit_Private.h"
#include <CoreFoundation/CoreFoundation.h>
#include <mach/mach_time.h>
#include <stdint.h>
#include <stdio.h>
#include <unistd.h> // for usleep

// Global client reference
static IOHIDEventSystemClientRef ioSystemClient = NULL;

// Sender ID is crucial for iOS 14+.
// In a real app, this should be dynamically retrieved or hardcoded based on the
// device board. Since we don't have the board ID, we use a common reliable
// default or 0xDEFACED (mock).
// iOS 15.8.5 compatible Sender ID (Virtual Service)
#define K_SENDER_ID 0x0000000100000000ULL

#define CLAMP(x, low, high)                                                    \
  (((x) > (high)) ? (high) : (((x) < (low)) ? (low) : (x)))

// Field defs if missing
#ifndef kIOHIDEventFieldDigitizerIsTouch
#define kIOHIDEventFieldDigitizerIsTouch ((kIOHIDEventTypeDigitizer << 16) | 16)
#endif

void init_touch_system() {
  if (ioSystemClient == NULL) {
    // Passing NULL allocator is standard
    ioSystemClient = IOHIDEventSystemClientCreate(NULL);
    if (ioSystemClient) {
      printf("[TouchSim] System client created.\n");
    } else {
      printf("[TouchSim] FATAL: Failed to create IOHIDEventSystemClient!\n");
    }
  }
}

// --- Low Level Event Senders ---

void send_digitizer_event(float x, float y, int type) {
  if (!ioSystemClient)
    init_touch_system();
  if (!ioSystemClient) {
    printf("[TouchSim] ERROR: No IOHIDEventSystemClient!\n");
    return;
  }

  // Safety Clamp
  x = CLAMP(x, 0.0f, 1.0f);
  y = CLAMP(y, 0.0f, 1.0f);

  uint32_t eventMask = 0;
  uint32_t touchValue = 0;

  // Based on IOKit_Private.h - more precise event masks for iOS 15
  if (type == 1) { // Touch Down
    eventMask = kIOHIDDigitizerEventTouch | kIOHIDDigitizerEventRange |
                kIOHIDDigitizerEventStart;
    touchValue = 1;
  } else if (type == 2) { // Touch Move
    eventMask = kIOHIDDigitizerEventTouch | kIOHIDDigitizerEventRange |
                kIOHIDDigitizerEventPosition;
    touchValue = 1;
  } else if (type == 3) { // Touch Up
    eventMask = kIOHIDDigitizerEventRange | kIOHIDDigitizerEventIdentity;
    touchValue = 0;
  }

  uint64_t now = mach_absolute_time();

  // Create digitizer event with normalized coordinates (0.0 - 1.0)
  IOHIDEventRef event = IOHIDEventCreateDigitizerEvent(kCFAllocatorDefault, now,
                                                       kIOHIDEventTypeDigitizer,
                                                       0, // digitizer index
                                                       1, // finger index
                                                       eventMask,
                                                       0,    // button mask
                                                       x, y, // normalized X, Y
                                                       0,    // Z
                                                       0,    // tip pressure
                                                       0,    // barrel pressure
                                                       0,    // twist
                                                       0,    // range
                                                       0     // touch
  );

  if (!event) {
    printf("[TouchSim] ERROR: Failed to create event!\n");
    return;
  }

  // Set all required fields explicitly for iOS 15 compatibility
  IOHIDEventSetIntegerValue(event, kIOHIDEventFieldDigitizerTouch, touchValue);
  IOHIDEventSetIntegerValue(event, kIOHIDEventFieldDigitizerRange,
                            (type == 3) ? 0 : 1);
  IOHIDEventSetIntegerValue(event, kIOHIDEventFieldDigitizerIsTouch,
                            touchValue);

  // Set index and identity
  IOHIDEventSetIntegerValue(event, kIOHIDEventFieldDigitizerIndex, 0);
  IOHIDEventSetIntegerValue(event, kIOHIDEventFieldDigitizerIdentity, 1);

  // Set event type
  IOHIDEventSetIntegerValue(event, kIOHIDEventFieldDigitizerType,
                            kIOHIDDigitizerTransducerTypeFinger);

  // Critical: Set sender ID for iOS 15
  IOHIDEventSetSenderID(event, K_SENDER_ID);

  // Dispatch the event
  printf("[TouchSim] Dispatching type=%d mask=0x%x x=%.2f y=%.2f\n", type,
         eventMask, x, y);
  IOHIDEventSystemClientDispatchEvent(ioSystemClient, event);

  CFRelease(event);
}

void perform_touch(float x, float y) {
  send_digitizer_event(x, y, 1); // Down
  usleep(60000);                 // 60ms hold
  send_digitizer_event(x, y, 3); // Up
  printf("[TouchSim] Tapped (%.2f, %.2f)\n", x, y);
}

void perform_swipe(float x1, float y1, float x2, float y2, float duration_sec) {
  printf("[TouchSim] Swipe Start (%.2f, %.2f) -> (%.2f, %.2f)\n", x1, y1, x2,
         y2);

  int steps = (int)(duration_sec * 60); // Reduce to 60Hz for stability
  if (steps < 10)
    steps = 10;

  // 1. Down
  send_digitizer_event(x1, y1, 1);
  usleep(10000);

  // 2. Move (Interpolate)
  for (int i = 1; i <= steps; i++) {
    float t = (float)i / steps;
    // Linear interpolation
    float cx = x1 + (x2 - x1) * t;
    float cy = y1 + (y2 - y1) * t;

    send_digitizer_event(cx, cy, 2);

    usleep((useconds_t)(duration_sec * 1000000 / steps));
  }

  // 3. Up
  send_digitizer_event(x2, y2, 3);
  printf("[TouchSim] Swipe End\n");

  // Force reset client after complex gesture to prevent stalls
  if (ioSystemClient) {
    CFRelease(ioSystemClient);
    ioSystemClient = NULL;
  }
}

// Main helper removed to avoid conflict with main.m
// int main(int argc, char *argv[]) {
//     printf("Starting TrollTouch Simulator...\n");
//     init_touch_system();
//     perform_touch(0.5, 0.5);
//     return 0;
// }
