//
//  XCTestRunner.h
//  TrollTouch
//
//  Run XCTest without Xcode - directly from TrollStore app
//

#import <Foundation/Foundation.h>

@interface XCTestRunner : NSObject

@property(nonatomic, assign, readonly) BOOL isRunning;

// Start automation test
+ (void)startAutomation;

// Stop automation test
+ (void)stopAutomation;

// Check if tests are running
+ (BOOL)isRunning;

@end
