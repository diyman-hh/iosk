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

  // Try BOTH locations - Media/Downloads AND Documents
  NSString *mediaLogDir = @"/var/mobile/Media/Downloads/TrollTouch_Logs";
  NSString *docsDir = [NSSearchPathForDirectoriesInDomains(
      NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
  NSString *docsLogDir =
      [docsDir stringByAppendingPathComponent:@"TrollTouch_Logs"];

  // Create timestamp for filename
  NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
  [formatter setDateFormat:@"yyyy-MM-dd_HH-mm-ss"];
  NSString *timestamp = [formatter stringFromDate:[NSDate date]];
  NSString *filename = [NSString stringWithFormat:@"agent_%@.log", timestamp];

  // Try Media/Downloads first (like old TrollTouch)
  BOOL mediaSuccess = NO;
  BOOL isDir = NO;
  if ([fm fileExistsAtPath:mediaLogDir isDirectory:&isDir] && !isDir) {
    [fm removeItemAtPath:mediaLogDir error:nil];
  }

  if (![fm fileExistsAtPath:mediaLogDir]) {
    NSError *error = nil;
    [fm createDirectoryAtPath:mediaLogDir
        withIntermediateDirectories:YES
                         attributes:@{NSFilePosixPermissions : @0777}
                              error:&error];
    if (!error) {
      mediaSuccess = YES;
    }
  } else {
    mediaSuccess = YES;
  }

  // Always create Documents directory as fallback
  if (![fm fileExistsAtPath:docsLogDir]) {
    [fm createDirectoryAtPath:docsLogDir
        withIntermediateDirectories:YES
                         attributes:@{NSFilePosixPermissions : @0777}
                              error:nil];
  }

  // Use Documents as primary (guaranteed accessible in Files app)
  NSString *logDir = docsLogDir;
  self.logFilePath = [logDir stringByAppendingPathComponent:filename];

  NSLog(@"[FileLogger] ✅ Using log directory: %@", logDir);
  NSLog(@"[FileLogger] 📝 Log file will be: %@", self.logFilePath);

  // Create file with full permissions
  NSDictionary *attributes = @{NSFilePosixPermissions : @0666};
  [[NSData data] writeToFile:self.logFilePath
                     options:NSDataWritingAtomic
                       error:nil];
  [fm setAttributes:attributes ofItemAtPath:self.logFilePath error:nil];

  // Also try to create in Media if it worked
  if (mediaSuccess) {
    NSString *mediaLogPath =
        [mediaLogDir stringByAppendingPathComponent:filename];
    [[NSData data] writeToFile:mediaLogPath
                       options:NSDataWritingAtomic
                         error:nil];
    NSLog(@"[FileLogger] 📝 Also created log at: %@", mediaLogPath);
  }

  // Open file handle
  self.fileHandle = [NSFileHandle fileHandleForWritingAtPath:self.logFilePath];
  if (!self.fileHandle) {
    NSLog(@"[FileLogger] ❌ Failed to open file handle for: %@",
          self.logFilePath);
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
