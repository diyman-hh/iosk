//
//  IOKit_Private.h
//  TrollTouch
//
//  Created for TrollStore Automation
//

#ifndef IOKit_Private_h
#define IOKit_Private_h

#include <CoreFoundation/CoreFoundation.h>
#include <mach/mach.h>

// --- IOHIDEvent Types ---

typedef struct __IOHIDEvent *IOHIDEventRef;
typedef struct __IOHIDEventSystemClient *IOHIDEventSystemClientRef;
typedef struct __IOHIDServiceClient *IOHIDServiceClientRef;

// The type of event (Digitizer = Touch)
#define kIOHIDEventTypeDigitizer 11
#define kIOHIDEventTypeHandwriting 7

// Touch phases
#define kIOHIDDigitizerEventTouch          0x00000001
#define kIOHIDDigitizerEventRange          0x00000002
#define kIOHIDDigitizerEventTouchIdentifier 0x00000004
#define kIOHIDDigitizerEventIdentity       0x00000020

// Fields for creating the event
enum {
    kIOHIDDigitizerEventUpdate          = 0x01,
    kIOHIDDigitizerEventCancel          = 0x02,
    kIOHIDDigitizerEventStart           = 0x04
};

// --- Function Prototypes (Private) ---

// Create the system client which connects to the HID system
IOHIDEventSystemClientRef IOHIDEventSystemClientCreate(CFAllocatorRef allocator);

// Create a digitizer (touch) event
// Note: The signature of this function changes slightly between iOS versions.
// This is the standard signature for iOS 11-15.
IOHIDEventRef IOHIDEventCreateDigitizerEvent(
    CFAllocatorRef allocator,
    uint64_t timeStamp,
    uint32_t transducerType,
    uint32_t index,
    uint32_t identity,
    uint32_t eventMask,
    uint32_t buttonMask,
    float x,
    float y,
    float z,
    float tipPressure,
    float barrelPressure,
    Boolean range,
    Boolean touch,
    uint32_t options
);

// Set the sender ID (Critical for iOS 14+)
void IOHIDEventSetSenderID(IOHIDEventRef event, uint64_t senderID);

// Dispatch the event to the system
void IOHIDEventSystemClientDispatchEvent(IOHIDEventSystemClientRef client, IOHIDEventRef event);

// --- Helpers ---

// Getting uptime for timestamp
extern uint64_t mach_absolute_time(void);

#endif /* IOKit_Private_h */
