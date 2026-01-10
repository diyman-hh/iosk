//
//  FileLogger.m
//  TrollTouchAgent
//
//  File-based logging for easy debugging
//

#import "FileLogger.h"

@interface FileLogger ()
@property(nonatomic, strong) NSString *logFilePath;
@property(nonatomic, strong) NSFileHandle *fileHandle;
@property(nonatomic, strong) dispatch_queue_t logQueue;
@end

@implementation FileLogger

+ (instancetype)sharedLogger {
  static FileLogger *instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[FileLogger alloc] init];
  });
  return instance;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    self.logQueue = dispatch_queue_create("com.trolltouch.filelogger",
                                          DISPATCH_QUEUE_SERIAL);
    [self setupLogFile];
  }
  return self;
}

- (void)setupLogFile {
  // Create log directory
  NSString *downloadsPath = @"/var/mobile/Downloads";
  NSString *logDir =
      [downloadsPath stringByAppendingPathComponent:@"TrollTouch_Logs"];

  NSFileManager *fm = [NSFileManager defaultManager];
  NSError *error = nil;

  // Create directory if it doesn't exist
  if (![fm fileExistsAtPath:logDir]) {
    [fm createDirectoryAtPath:logDir
        withIntermediateDirectories:YES
                         attributes:nil
                              error:&error];
    if (error) {
      NSLog(@"[FileLogger] ❌ Failed to create log directory: %@", error);
      // Fallback to Documents
      logDir = [NSSearchPathForDirectoriesInDomains(
          NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
      logDir = [logDir stringByAppendingPathComponent:@"TrollTouch_Logs"];
      [fm createDirectoryAtPath:logDir
          withIntermediateDirectories:YES
                           attributes:nil
                                error:nil];
    }
  }

  // Create log file with timestamp
  NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
  [formatter setDateFormat:@"yyyy-MM-dd_HH-mm-ss"];
  NSString *timestamp = [formatter stringFromDate:[NSDate date]];
  NSString *filename = [NSString stringWithFormat:@"agent_%@.log", timestamp];

  self.logFilePath = [logDir stringByAppendingPathComponent:filename];

  // Create file
  [fm createFileAtPath:self.logFilePath contents:nil attributes:nil];

  // Open file handle
  self.fileHandle = [NSFileHandle fileHandleForWritingAtPath:self.logFilePath];

  NSLog(@"[FileLogger] 📝 Log file created at: %@", self.logFilePath);

  // Write header
  NSString *header =
      [NSString stringWithFormat:@"TrollTouchAgent Log\nStarted: %@\n%@\n\n",
                                 [NSDate date],
                                 [@"=" stringByPaddingToLength:50
                                                    withString:@"="
                                               startingAtIndex:0]];
  [self writeToFile:header];
}

- (void)log:(NSString *)message {
  dispatch_async(self.logQueue, ^{
    NSString *timestamp = [self currentTimestamp];
    NSString *logEntry =
        [NSString stringWithFormat:@"[%@] %@\n", timestamp, message];

    // Write to file
    [self writeToFile:logEntry];

    // Also log to console
    NSLog(@"%@", message);
  });
}

- (void)writeToFile:(NSString *)text {
  if (self.fileHandle) {
    NSData *data = [text dataUsingEncoding:NSUTF8StringEncoding];
    @try {
      [self.fileHandle writeData:data];
      [self.fileHandle synchronizeFile];
    } @catch (NSException *exception) {
      NSLog(@"[FileLogger] ❌ Failed to write to log: %@", exception);
    }
  }
}

- (NSString *)currentTimestamp {
  NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
  [formatter setDateFormat:@"HH:mm:ss.SSS"];
  return [formatter stringFromDate:[NSDate date]];
}

- (void)clearLog {
  dispatch_async(self.logQueue, ^{
    if (self.fileHandle) {
      [self.fileHandle truncateFileAtOffset:0];
      [self.fileHandle synchronizeFile];
    }
  });
}

- (NSString *)getLogPath {
  return self.logFilePath;
}

- (void)dealloc {
  if (self.fileHandle) {
    [self.fileHandle closeFile];
  }
}

@end
