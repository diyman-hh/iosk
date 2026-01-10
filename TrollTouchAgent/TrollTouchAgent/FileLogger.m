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
  NSFileManager *fm = [NSFileManager defaultManager];
  NSError *error = nil;

  // Try multiple locations in order of preference
  NSArray *possiblePaths = @[
    @"/var/mobile/Downloads/TrollTouch_Logs",
    [NSHomeDirectory()
        stringByAppendingPathComponent:@"Downloads/TrollTouch_Logs"],
    [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,
                                          YES) firstObject]
        stringByAppendingPathComponent:@"TrollTouch_Logs"]
  ];

  NSString *logDir = nil;

  for (NSString *path in possiblePaths) {
    // Try to create directory
    if (![fm fileExistsAtPath:path]) {
      [fm createDirectoryAtPath:path
          withIntermediateDirectories:YES
                           attributes:nil
                                error:&error];
    }

    // Check if we can write to it
    if ([fm isWritableFileAtPath:[path stringByDeletingLastPathComponent]]) {
      logDir = path;
      NSLog(@"[FileLogger] ✅ Using log directory: %@", logDir);
      break;
    } else {
      NSLog(@"[FileLogger] ⚠️ Cannot write to: %@", path);
    }
  }

  if (!logDir) {
    NSLog(@"[FileLogger] ❌ No writable directory found!");
    return;
  }

  // Create log file with timestamp
  NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
  [formatter setDateFormat:@"yyyy-MM-dd_HH-mm-ss"];
  NSString *timestamp = [formatter stringFromDate:[NSDate date]];
  NSString *filename = [NSString stringWithFormat:@"agent_%@.log", timestamp];

  self.logFilePath = [logDir stringByAppendingPathComponent:filename];

  // Create file
  BOOL created = [fm createFileAtPath:self.logFilePath
                             contents:nil
                           attributes:nil];
  if (!created) {
    NSLog(@"[FileLogger] ❌ Failed to create log file at: %@",
          self.logFilePath);
    return;
  }

  // Open file handle
  self.fileHandle = [NSFileHandle fileHandleForWritingAtPath:self.logFilePath];
  if (!self.fileHandle) {
    NSLog(@"[FileLogger] ❌ Failed to open file handle");
    return;
  }

  NSLog(@"[FileLogger] 📝 Log file created at: %@", self.logFilePath);

  // Write header
  NSString *header = [NSString
      stringWithFormat:
          @"TrollTouchAgent Log\nStarted: %@\nLog Path: %@\n%@\n\n",
          [NSDate date], self.logFilePath,
          [@"=" stringByPaddingToLength:50 withString:@"=" startingAtIndex:0]];
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
