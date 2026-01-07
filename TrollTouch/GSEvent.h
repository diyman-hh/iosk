//
//  GSEvent.h
//  TrollTouch
//
//  GraphicsServices Event API for iOS touch injection
//

#ifndef GSEvent_h
#define GSEvent_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// GraphicsServices types
typedef struct __GSEvent *GSEventRef;

// Event types
typedef enum {
  kGSEventTypeKeyDown = 1,
  kGSEventTypeKeyUp = 2,
  kGSEventTypeMouseDown = 3001,
  kGSEventTypeMouseUp = 3002,
  kGSEventTypeMouseMoved = 3003,
  kGSEventTypeMouseDragged = 3004,
} GSEventType;

// Hand info types
typedef enum {
  kGSHandInfoTypeTouchDown = 1,
  kGSHandInfoTypeTouchMoved = 2,
  kGSHandInfoTypeTouchUp = 6,
} GSHandInfoType;

// Function prototypes
#ifdef __cplusplus
extern "C" {
#endif

// Create a touch event
GSEventRef GSEventCreateWithEventRecord(void *eventRecord);

// Send event to application
void GSSendEvent(GSEventRef event, mach_port_t port);
void GSSendSystemEvent(GSEventRef event);

// Get application port
mach_port_t GSGetPurpleSystemEventPort(void);

// Memory management
CFTypeID GSEventGetTypeID(void);

#ifdef __cplusplus
}
#endif

#endif /* GSEvent_h */
