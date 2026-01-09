//
//  AppDelegate.m
//  TrollTouch (Simplified for XCTest)
//

#import "AppDelegate.h"
#import "BundleLoader.h"
#import "RootViewController.h"


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

  // Load UITests bundle first
  NSLog(@"[AppDelegate] 🚀 Loading UITests bundle...");
  BOOL bundleLoaded = [BundleLoader loadUITestsBundle];
  if (bundleLoaded) {
    NSLog(@"[AppDelegate] ✅ UITests bundle loaded successfully");
  } else {
    NSLog(@"[AppDelegate] ⚠️ Failed to load UITests bundle");
  }

  self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  self.window.rootViewController = [[RootViewController alloc] init];
  [self.window makeKeyAndVisible];
  return YES;
}

@end
