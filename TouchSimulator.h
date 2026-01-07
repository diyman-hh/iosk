#ifndef TouchSimulator_h
#define TouchSimulator_h

#include "IOKit_Private.h"
#include <stdio.h>


// Initialize the IOHIDEventSystemClient
void init_touch_system(void);

// Perform a single tap at (x, y) coordinates (0.0 - 1.0)
void perform_touch(float x, float y);

// Perform a swipe from (x1, y1) to (x2, y2) with duration in seconds
void perform_swipe(float x1, float y1, float x2, float y2, float duration_sec);

// Low-level event sender (exposed if needed)
void send_digitizer_event(float x, float y, int type);

#endif /* TouchSimulator_h */
