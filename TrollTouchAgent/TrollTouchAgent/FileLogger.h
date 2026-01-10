//
//  FileLogger.h
//  TrollTouchAgent
//
//  File-based logging for easy debugging
//

#import <Foundation/Foundation.h>

@interface FileLogger : NSObject

+ (instancetype)sharedLogger;

- (void)log:(NSString *)message;
- (void)clearLog;
- (NSString *)getLogPath;

@end
