//
//  TouchSimulator.c
//  TrollTouch
//

#include "IOKit_Private.h"
#include <stdio.h>
#include <unistd.h> // for usleep

// Global client reference
static IOHIDEventSystemClientRef ioSystemClient = NULL;

// Sender ID is crucial for iOS 14+. 
// In a real app, this should be dynamically retrieved or hardcoded based on the device board.
// Since we don't have the board ID, we use a common reliable default or 0xDEFACED (mock).
#define K_SENDER_ID 0x000000010000027F 

void init_touch_system() {
    if (ioSystemClient == NULL) {
        ioSystemClient = IOHIDEventSystemClientCreate(kCFAllocatorDefault);
        if (ioSystemClient) {
            printf("[TouchSimulator] System client created successfully.\n");
        } else {
            printf("[TouchSimulator] Failed to create system client! Entitlements missing?\n");
        }
    }
}

void perform_touch(float x, float y) {
    if (!ioSystemClient) init_touch_system();
    
    // Convert logic coordinates (0.0 - 1.0) or points if needed.
    // IOHID usually expects normalized coordinates 0.0 to 1.0 on some endpoints, 
    // or exact pixel points on others. Let's assume input is 0.0-1.0 normalized.
    
    uint64_t now = mach_absolute_time();
    
    // 1. Touch Down
    IOHIDEventRef touchDown = IOHIDEventCreateDigitizerEvent(
        kCFAllocatorDefault,
        now,
        kIOHIDEventTypeDigitizer, // Transducer Type
        0, // Index
        1, // Identity (Finger ID)
        kIOHIDDigitizerEventTouch | kIOHIDDigitizerEventRange | kIOHIDDigitizerEventStart,
        0, // Button Mask
        x, y, 0, // X, Y, Z
        0, 0, // Pressure
        true, // Range
        true, // Touch (Contact)
        0
    );
    IOHIDEventSetSenderID(touchDown, K_SENDER_ID);
    IOHIDEventSystemClientDispatchEvent(ioSystemClient, touchDown);
    CFRelease(touchDown);
    
    // Hold for a tiny bit (simulating a tap)
    usleep(50000); // 50ms
    
    // 2. Touch Up
    now = mach_absolute_time();
    IOHIDEventRef touchUp = IOHIDEventCreateDigitizerEvent(
        kCFAllocatorDefault,
        now,
        kIOHIDEventTypeDigitizer,
        0,
        1,
        kIOHIDDigitizerEventTouch | kIOHIDDigitizerEventRange | kIOHIDDigitizerEventCancel,
        0,
        x, y, 0,
        0, 0,
        true,
        false, // Touch = false (Lift)
        0
    );
    IOHIDEventSetSenderID(touchUp, K_SENDER_ID);
    IOHIDEventSystemClientDispatchEvent(ioSystemClient, touchUp);
    CFRelease(touchUp);
    
    printf("[TouchSimulator] Tapped at (%f, %f)\n", x, y);
}

// Main helper removed to avoid conflict with main.m
// int main(int argc, char *argv[]) {
//     printf("Starting TrollTouch Simulator...\n");
//     init_touch_system();
//     perform_touch(0.5, 0.5);
//     return 0;
// }
