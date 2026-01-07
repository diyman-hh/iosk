//
//  BackboardServices.h
//  TrollTouch
//
//  Private API for backboardd - System-level touch injection
//

#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>


// Backboard Services private API
// This allows system-level event injection that works across apps

typedef struct __IOHIDEvent *IOHIDEventRef;

#ifdef __cplusplus
extern "C" {
#endif

// BackboardServices functions
void BKSendHIDEvent(IOHIDEventRef event);
mach_port_t BKSHIDServicesCopyEventPort(void);

// IOHIDEvent creation (from IOKit)
IOHIDEventRef IOHIDEventCreateDigitizerEvent(
    CFAllocatorRef allocator, AbsoluteTime timeStamp,
    IOHIDDigitizerTransducerType type, uint32_t index, uint32_t identity,
    uint32_t eventMask, uint32_t buttonMask, IOHIDFloat x, IOHIDFloat y,
    IOHIDFloat z, IOHIDFloat tipPressure, IOHIDFloat twist, Boolean range);

IOHIDEventRef IOHIDEventCreateDigitizerFingerEvent(
    CFAllocatorRef allocator, AbsoluteTime timeStamp, uint32_t index,
    uint32_t identity, uint32_t eventMask, IOHIDFloat x, IOHIDFloat y,
    IOHIDFloat z, IOHIDFloat tipPressure, IOHIDFloat twist, Boolean range);

void IOHIDEventSetIntegerValue(IOHIDEventRef event, IOHIDEventField field,
                               int value);
void IOHIDEventSetFloatValue(IOHIDEventRef event, IOHIDEventField field,
                             float value);

#ifdef __cplusplus
}
#endif
