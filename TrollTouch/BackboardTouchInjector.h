//
//  BackboardTouchInjector.h
//  TrollTouch
//
//  System-level touch injection using BackboardServices
//  This works across all apps without needing foreground
//

#import <Foundation/Foundation.h>

@interface BackboardTouchInjector : NSObject

+ (instancetype)sharedInjector;

// Initialize the injector
- (BOOL)initialize;

// Inject touch at normalized coordinates (0.0-1.0)
- (void)tapAtX:(float)x y:(float)y;

// Inject swipe from (x1,y1) to (x2,y2) over duration seconds
- (void)swipeFromX:(float)x1
                 y:(float)y1
               toX:(float)x2
                 y:(float)y2
          duration:(float)duration;

@end
