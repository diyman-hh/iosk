//
//  BundleLoader.m
//  Helper to load UITests bundle at runtime
//

#import "BundleLoader.h"
#import <dlfcn.h>

@implementation BundleLoader

+ (BOOL)loadUITestsBundle {
  NSLog(@"[BundleLoader] 🔍 Attempting to load UITests bundle...");

  // Get main bundle path
  NSString *mainBundlePath = [[NSBundle mainBundle] bundlePath];
  NSString *plugInsPath =
      [mainBundlePath stringByAppendingPathComponent:@"PlugIns"];
  NSString *uiTestsBundlePath =
      [plugInsPath stringByAppendingPathComponent:@"TrollTouchUITests.xctest"];

  NSLog(@"[BundleLoader] 📂 Looking for bundle at: %@", uiTestsBundlePath);

  // Check if bundle exists
  if (![[NSFileManager defaultManager] fileExistsAtPath:uiTestsBundlePath]) {
    NSLog(@"[BundleLoader] ❌ UITests bundle not found at path");
    return NO;
  }

  // Load the bundle
  NSBundle *uiTestsBundle = [NSBundle bundleWithPath:uiTestsBundlePath];
  if (!uiTestsBundle) {
    NSLog(@"[BundleLoader] ❌ Failed to create bundle object");
    return NO;
  }

  NSLog(@"[BundleLoader] 📦 Bundle object created: %@", uiTestsBundle);

  // Load the bundle
  NSError *error = nil;
  BOOL loaded = [uiTestsBundle loadAndReturnError:&error];

  if (!loaded) {
    NSLog(@"[BundleLoader] ❌ Failed to load bundle: %@",
          error.localizedDescription);
    return NO;
  }

  NSLog(@"[BundleLoader] ✅ UITests bundle loaded successfully");

  // Try to get AutomationServer class
  Class serverClass = NSClassFromString(@"AutomationServer");
  if (serverClass) {
    NSLog(@"[BundleLoader] ✅ AutomationServer class found");

    // Try to start the server
    SEL sharedSel = NSSelectorFromString(@"sharedServer");
    if ([serverClass respondsToSelector:sharedSel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
      id server = [serverClass performSelector:sharedSel];
#pragma clang diagnostic pop

      if (server) {
        NSLog(@"[BundleLoader] ✅ AutomationServer instance created: %@",
              server);

        // Check if server is running
        SEL isRunningSel = NSSelectorFromString(@"isRunning");
        if ([server respondsToSelector:isRunningSel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
          BOOL running = (BOOL)[server performSelector:isRunningSel];
#pragma clang diagnostic pop
          NSLog(@"[BundleLoader] 📊 Server running status: %d", running);
        }

        return YES;
      }
    }
  } else {
    NSLog(@"[BundleLoader] ⚠️ AutomationServer class not found after loading "
          @"bundle");
  }

  return loaded;
}

+ (BOOL)isUITestsBundleLoaded {
  Class serverClass = NSClassFromString(@"AutomationServer");
  return serverClass != nil;
}

@end
