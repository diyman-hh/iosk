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
@property(nonatomic, strong)
    NSFileHandle *mediaFileHandle; // Handle for Media/Downloads
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

  // 1. Setup Documents Logger (Primary)
  NSString *logDir = docsLogDir;
  self.logFilePath = [logDir stringByAppendingPathComponent:filename];

  NSDictionary *attributes = @{NSFilePosixPermissions : @0666};
  [[NSData data] writeToFile:self.logFilePath
                     options:NSDataWritingAtomic
                       error:nil];
  [fm setAttributes:attributes ofItemAtPath:self.logFilePath error:nil];

  self.fileHandle = [NSFileHandle fileHandleForWritingAtPath:self.logFilePath];
  NSLog(@"[FileLogger] 📝 Primary Log: %@", self.logFilePath);

  // 2. Setup Media/Downloads Logger (Secondary - for i4Tools visibility)
  if (mediaSuccess) {
    NSString *mediaLogPath =
        [mediaLogDir stringByAppendingPathComponent:filename];
    [[NSData data] writeToFile:mediaLogPath
                       options:NSDataWritingAtomic
                         error:nil];
    [fm setAttributes:attributes ofItemAtPath:mediaLogPath error:nil];

    self.mediaFileHandle =
        [NSFileHandle fileHandleForWritingAtPath:mediaLogPath];
    if (self.mediaFileHandle) {
      NSLog(@"[FileLogger] 📝 Secondary Log (Public): %@", mediaLogPath);
    }
  }

  // Write header
  NSString *header = [NSString
      stringWithFormat:
          @"TrollTouchAgent Log\nStarted: %@\nLog Path: %@\n%@\n\n",
          [NSDate date], self.logFilePath,
          [@"=" stringByPaddingToLength:50 withString:@"=" startingAtIndex:0]];
  [self writeToFile:header];
}

- (void)writeToFile:(NSString *)text {
  NSData *data = [text dataUsingEncoding:NSUTF8StringEncoding];

  // Write to Primary (Documents)
  if (self.fileHandle) {
    @try {
      [self.fileHandle writeData:data];
      // Only sync strictly necessary or periodically to save I/O
      // [self.fileHandle synchronizeFile];
    } @catch (NSException *exception) {
      NSLog(@"[FileLogger] ❌ Failed to write to Doc log: %@", exception);
    }
  }

  // Write to Secondary (Media/Downloads)
  if (self.mediaFileHandle) {
    @try {
      [self.mediaFileHandle writeData:data];
      // [self.mediaFileHandle synchronizeFile];
    } @catch (NSException *exception) {
      NSLog(@"[FileLogger] ❌ Failed to write to Media log: %@", exception);
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
