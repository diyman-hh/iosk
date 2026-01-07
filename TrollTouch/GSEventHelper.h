//
//  GSEventHelper.h
//  TrollTouch
//

#ifndef GSEventHelper_h
#define GSEventHelper_h

#import <Foundation/Foundation.h>

// Initialize GSEvent system
void initGSEventSystem(void);

// Send touch events
void sendGSTouch(float x, float y, int phase);
void performGSTouch(float x, float y);
void performGSSwipe(float x1, float y1, float x2, float y2, float duration);

#endif /* GSEventHelper_h */
