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
  if (!ioSystemClient)
    return;

  uint32_t eventMask = 0;
  // Based on IOKit_Private.h fixes
  if (type == 1)
    eventMask = kIOHIDDigitizerEventTouch | kIOHIDDigitizerEventRange |
                kIOHIDDigitizerEventStart;
  if (type == 2)
    eventMask = kIOHIDDigitizerEventTouch | kIOHIDDigitizerEventRange |
                kIOHIDDigitizerEventPosition;
  if (type == 3)
    eventMask = kIOHIDDigitizerEventTouch | kIOHIDDigitizerEventRange |
                kIOHIDDigitizerEventStop | kIOHIDDigitizerEventIdentity;

  uint64_t now = mach_absolute_time();

  // iOS 11+ Signature
  IOHIDEventRef event = IOHIDEventCreateDigitizerEvent(
      kCFAllocatorDefault, now, kIOHIDEventTypeDigitizer, 0, 1, eventMask, 0, x,
      y, 0, 0, 0, 0, 0, 0);

  if (!event)
    return;

  // Set standard fields manually for safety
  IOHIDEventSetIntegerValue(event, kIOHIDEventFieldDigitizerTouch,
                            (type == 3) ? 0 : 1);
  IOHIDEventSetIntegerValue(event, kIOHIDEventFieldDigitizerRange,
                            (type == 3) ? 0 : 1);

  // iOS 15+ might check this
  IOHIDEventSetIntegerValue(event, kIOHIDEventFieldDigitizerIsTouch,
                            (type == 3) ? 0 : 1);

  IOHIDEventSetSenderID(event, K_SENDER_ID);
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
}

// Main helper removed to avoid conflict with main.m
// int main(int argc, char *argv[]) {
//     printf("Starting TrollTouch Simulator...\n");
//     init_touch_system();
//     perform_touch(0.5, 0.5);
//     return 0;
// }
