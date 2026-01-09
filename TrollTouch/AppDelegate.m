//
//  AppDelegate.m
//  TrollTouch (Simplified for XCTest)
//

#import "AppDelegate.h"
#import "BundleLoader.h"
#import "RootViewController.h"

// Helper to write startup logs to file
static void logStartup(NSString *message) {
  NSString *logDir = @"/var/mobile/Media/Downloads/TrollTouch_Logs";
  NSString *logPath = [logDir stringByAppendingPathComponent:@"startup.log"];

  [[NSFileManager defaultManager] createDirectoryAtPath:logDir
                            withIntermediateDirectories:YES
                                             attributes:nil
                                                  error:nil];

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

  NSLog(@"%@", message);
}

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

  logStartup(@"========================================");
  logStartup(@"[AppDelegate] 🚀 TrollTouch Starting...");
  logStartup(@"========================================");

  // Load UITests bundle first - DISABLED for TouchSimulator
  // logStartup(@"[AppDelegate] 📦 Loading UITests bundle...");
  // BOOL bundleLoaded = [BundleLoader loadUITestsBundle];
  // if (bundleLoaded) {
  //   logStartup(@"[AppDelegate] ✅ UITests bundle loaded successfully");
  // } else {
  //   logStartup(@"[AppDelegate] ❌ Failed to load UITests bundle");
  // }

  // Start Automation
  [[AutomationManager sharedManager] startAutomation];

  logStartup(@"[AppDelegate] 🖥️ Creating main window...");
  self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  self.window.rootViewController = [[RootViewController alloc] init];
  [self.window makeKeyAndVisible];

  logStartup(@"[AppDelegate] ✅ App initialization complete");
  logStartup(@"========================================");

  return YES;
}

@end
