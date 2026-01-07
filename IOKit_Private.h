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

// --- IOHIDEvent Types ---

typedef struct __IOHIDEvent *IOHIDEventRef;
typedef struct __IOHIDEventSystemClient *IOHIDEventSystemClientRef;
typedef struct __IOHIDServiceClient *IOHIDServiceClientRef;

// The type of event (Digitizer = Touch)
#define kIOHIDEventTypeDigitizer 11
#define kIOHIDEventTypeHandwriting 7

// Digitizer Event Masks (Corrected to avoid overlap)
#define kIOHIDDigitizerEventRange 0x00000001
#define kIOHIDDigitizerEventTouch 0x00000002
#define kIOHIDDigitizerEventPosition 0x00000004
#define kIOHIDDigitizerEventStop 0x00000008
#define kIOHIDDigitizerEventStart 0x00000010
#define kIOHIDDigitizerEventTouchIdentifier 0x00000020
#define kIOHIDDigitizerEventIdentity 0x00000040

// Fields for Event creation (Enum kept for legacy compatibility if needed, but
// masks above are preferred)
enum {
  kIOHIDDigitizerEventUpdate = 0x01,
  kIOHIDDigitizerEventCancel = 0x02,
  // kIOHIDDigitizerEventStart           = 0x04 // Commented to use Macro above
};

// Field Indices for SetIntegerValue
#define kIOHIDEventFieldDigitizerTouch ((kIOHIDEventTypeDigitizer << 16) | 3)
#define kIOHIDEventFieldDigitizerRange ((kIOHIDEventTypeDigitizer << 16) | 4)
#define kIOHIDEventFieldDigitizerIndex ((kIOHIDEventTypeDigitizer << 16) | 0)
#define kIOHIDEventFieldDigitizerIdentity ((kIOHIDEventTypeDigitizer << 16) | 1)
#define kIOHIDEventFieldDigitizerType ((kIOHIDEventTypeDigitizer << 16) | 9)

// Digitizer Transducer Types
#define kIOHIDDigitizerTransducerTypeFinger 0

// --- Function Prototypes (Private) ---

// Create the system client which connects to the HID system
IOHIDEventSystemClientRef
IOHIDEventSystemClientCreate(CFAllocatorRef allocator);

// Create a digitizer (touch) event
IOHIDEventRef IOHIDEventCreateDigitizerEvent(
    CFAllocatorRef allocator, uint64_t timeStamp, uint32_t transducerType,
    uint32_t index, uint32_t identity, uint32_t eventMask, uint32_t buttonMask,
    float x, float y, float z, float tipPressure, float barrelPressure,
    Boolean range, Boolean touch, uint32_t options);

// Set the sender ID (Critical for iOS 14+)
void IOHIDEventSetSenderID(IOHIDEventRef event, uint64_t senderID);

// Set Integer Value (For updating fields like Touch/Range state)
void IOHIDEventSetIntegerValue(IOHIDEventRef event, uint32_t field, int value);

// Dispatch the event to the system
void IOHIDEventSystemClientDispatchEvent(IOHIDEventSystemClientRef client,
                                         IOHIDEventRef event);

// --- Helpers ---

// Getting uptime for timestamp
extern uint64_t mach_absolute_time(void);

#endif /* IOKit_Private_h */
