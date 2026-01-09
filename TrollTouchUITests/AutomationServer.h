//
//  AutomationServer.h
//  Simple HTTP server for receiving automation commands
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AutomationServer : NSObject

/// Shared server instance
+ (instancetype)sharedServer;

/// Start the server on specified port
/// @param port Port number (default: 8100)
- (void)startOnPort:(NSUInteger)port;

/// Stop the server
- (void)stop;

/// Check if server is running
@property(nonatomic, readonly) BOOL isRunning;

@end

NS_ASSUME_NONNULL_END
