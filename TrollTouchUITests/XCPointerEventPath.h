//
//  XCPointerEventPath.h
//  Private API declarations for XCTest touch injection
//  Based on WebDriverAgent implementation
//

#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// XCPointerEventPath - Core touch event path API
@interface XCPointerEventPath : NSObject

// Initialize for touch at a specific point
- (instancetype)initForTouchAtPoint:(CGPoint)point offset:(double)offset;

// Initialize for mouse at a specific point
- (instancetype)initForMouseAtPoint:(CGPoint)point offset:(double)offset;

// Move to a new point
- (void)moveToPoint:(CGPoint)point atOffset:(double)offset;

// Lift up (end touch)
- (void)liftUpAtOffset:(double)offset;

// Press down
- (void)pressDownAtOffset:(double)offset;

// Press down with specific pressure (for 3D Touch)
- (void)pressDownWithPressure:(double)pressure atOffset:(double)offset;

@end

// XCSynthesizedEventRecord - Event record container
@interface XCSynthesizedEventRecord : NSObject

// Initialize with name and orientation
- (instancetype)initWithName:(NSString *)name
        interfaceOrientation:(long long)orientation;

// Add a pointer event path to the record
- (void)addPointerEventPath:(XCPointerEventPath *)path;

@end

/// Forward declaration - XCUIDevice is provided by XCTest framework
@class XCUIDevice;

/// Category to declare private API method
@interface XCUIDevice (PrivateAPI)

- (void)synthesizeEvent:(XCSynthesizedEventRecord *)event
             completion:(void (^)(NSError *_Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
