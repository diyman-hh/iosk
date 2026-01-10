//
//  AgentServer.h
//  TrollTouchAgent
//

#import <Foundation/Foundation.h>

@interface AgentServer : NSObject

+ (instancetype)sharedServer;
- (void)startServerOnPort:(NSUInteger)port;
- (void)stopServer;

@end
