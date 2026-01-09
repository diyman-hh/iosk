//
//  BundleLoader.m
//  Helper to load UITests bundle at runtime
//

#import "BundleLoader.h"
#import <dlfcn.h>

// Helper function to write logs to file (shared with AppDelegate)
static void logToFile(NSString *message) {
  NSString *logDir = @"/var/mobile/Media/Downloads/TrollTouch_Logs";
  NSString *logPath = [logDir stringByAppendingPathComponent:@"startup.log"];

  // Create directory if needed
  [[NSFileManager defaultManager] createDirectoryAtPath:logDir
                            withIntermediateDirectories:YES
                                             attributes:nil
                                                  error:nil];

  // Append to log file
  NSString *timestamp =
      [NSDateFormatter localizedStringFromDate:[NSDate date]
                                     dateStyle:NSDateFormatterShortStyle
                                     timeStyle:NSDateFormatterMediumStyle];
  NSString *logLine =
      [NSString stringWithFormat:@"[%@] %@\n", timestamp, message];

  NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:logPath];
  if (fileHandle) {
    [fileHandle seekToEndOfFile];
    [fileHandle writeData:[logLine dataUsingEncoding:NSUTF8StringEncoding]];
    [fileHandle closeFile];
  } else {
    [logLine writeToFile:logPath
              atomically:YES
                encoding:NSUTF8StringEncoding
                   error:nil];
  }

  // Also NSLog for console
  NSLog(@"%@", message);
}

@implementation BundleLoader

+ (BOOL)loadUITestsBundle {
  logToFile(@"[BundleLoader] 🔍 Attempting to load UITests bundle...");

  // Try to preload XCTest.framework using dlopen
  logToFile(@"[BundleLoader] 🔧 Attempting to preload XCTest.framework...");

  NSString *mainBundlePath = [[NSBundle mainBundle] bundlePath];
  NSString *xctestFrameworkPath = [mainBundlePath
      stringByAppendingPathComponent:@"Frameworks/XCTest.framework/XCTest"];

  void *xctestHandle =
      dlopen([xctestFrameworkPath UTF8String], RTLD_NOW | RTLD_GLOBAL);
  if (xctestHandle) {
    logToFile(@"[BundleLoader] ✅ XCTest.framework preloaded successfully");
  } else {
    const char *error = dlerror();
    logToFile([NSString
        stringWithFormat:
            @"[BundleLoader] ⚠️ Failed to preload XCTest.framework: %s",
            error ?: "unknown error"]);

    // Try system path as fallback
    xctestHandle = dlopen("/System/Library/Frameworks/XCTest.framework/XCTest",
                          RTLD_NOW | RTLD_GLOBAL);
    if (xctestHandle) {
      logToFile(@"[BundleLoader] ✅ XCTest.framework loaded from system path");
    } else {
      error = dlerror();
      logToFile([NSString
          stringWithFormat:@"[BundleLoader] ⚠️ Failed to load from system: %s",
                           error ?: "unknown error"]);
    }
  }

  // Get main bundle path
  NSString *plugInsPath =
      [mainBundlePath stringByAppendingPathComponent:@"PlugIns"];
  NSString *uiTestsBundlePath =
      [plugInsPath stringByAppendingPathComponent:@"TrollTouchUITests.xctest"];

  logToFile(
      [NSString stringWithFormat:@"[BundleLoader] 📂 Looking for bundle at: %@",
                                 uiTestsBundlePath]);

  // Check if bundle exists
  if (![[NSFileManager defaultManager] fileExistsAtPath:uiTestsBundlePath]) {
    logToFile(@"[BundleLoader] ❌ UITests bundle not found at path");

    // List what's actually in PlugIns directory
    NSArray *plugInContents =
        [[NSFileManager defaultManager] contentsOfDirectoryAtPath:plugInsPath
                                                            error:nil];
    if (plugInContents) {
      logToFile([NSString
          stringWithFormat:@"[BundleLoader] 📋 PlugIns directory contains: %@",
                           plugInContents]);
    } else {
      logToFile(
          @"[BundleLoader] ⚠️ PlugIns directory does not exist or is empty");
    }

    return NO;
  }

  logToFile(@"[BundleLoader] ✅ Bundle file exists");

  // Load the bundle
  NSBundle *uiTestsBundle = [NSBundle bundleWithPath:uiTestsBundlePath];
  if (!uiTestsBundle) {
    logToFile(@"[BundleLoader] ❌ Failed to create bundle object");
    return NO;
  }

  logToFile(
      [NSString stringWithFormat:@"[BundleLoader] 📦 Bundle object created: %@",
                                 uiTestsBundle]);

  // Load the bundle
  NSError *error = nil;
  BOOL loaded = [uiTestsBundle loadAndReturnError:&error];

  if (!loaded) {
    logToFile([NSString
        stringWithFormat:@"[BundleLoader] ❌ Failed to load bundle: %@",
                         error.localizedDescription]);
    return NO;
  }

  logToFile(@"[BundleLoader] ✅ UITests bundle loaded successfully");

  // Try to get AutomationServer class
  Class serverClass = NSClassFromString(@"AutomationServer");
  if (serverClass) {
    logToFile(@"[BundleLoader] ✅ AutomationServer class found");

    // Try to start the server
    SEL sharedSel = NSSelectorFromString(@"sharedServer");
    if ([serverClass respondsToSelector:sharedSel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
      id server = [serverClass performSelector:sharedSel];
#pragma clang diagnostic pop

      if (server) {
        logToFile([NSString
            stringWithFormat:
                @"[BundleLoader] ✅ AutomationServer instance created: %@",
                server]);

        // Check if server is running
        SEL isRunningSel = NSSelectorFromString(@"isRunning");
        if ([server respondsToSelector:isRunningSel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
          BOOL running = (BOOL)[server performSelector:isRunningSel];
#pragma clang diagnostic pop
          logToFile([NSString
              stringWithFormat:@"[BundleLoader] 📊 Server running status: %d",
                               running]);
        }

        return YES;
      } else {
        logToFile(
            @"[BundleLoader] ⚠️ Failed to create AutomationServer instance");
      }
    } else {
      logToFile(@"[BundleLoader] ⚠️ sharedServer method not found");
    }
  } else {
    logToFile(@"[BundleLoader] ⚠️ AutomationServer class not found after "
              @"loading bundle");
  }

  return loaded;
}

+ (BOOL)isUITestsBundleLoaded {
  Class serverClass = NSClassFromString(@"AutomationServer");
  BOOL loaded = serverClass != nil;
  logToFile([NSString
      stringWithFormat:@"[BundleLoader] isUITestsBundleLoaded: %d", loaded]);
  return loaded;
}

@end
