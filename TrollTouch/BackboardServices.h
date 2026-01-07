//
//  BackboardServices.h
//  TrollTouch
//
//  Private API for backboardd - System-level touch injection
//

#import "IOKit_Private.h"
#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>


// Backboard Services private API
// This allows system-level event injection that works across apps

#ifdef __cplusplus
extern "C" {
#endif

// BackboardServices functions
void BKSendHIDEvent(IOHIDEventRef event);
mach_port_t BKSHIDServicesCopyEventPort(void);

// Note: IOHIDEvent functions are already declared in IOKit_Private.h
// We don't need to redeclare them here

#ifdef __cplusplus
}
#endif
