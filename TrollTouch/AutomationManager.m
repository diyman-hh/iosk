#import "AutomationManager.h"
#import "IOKit_Private.h"
#include "TouchSimulator.c" // Helper for touch events
#import <UIKit/UIKit.h>
#import <dlfcn.h>


// Internal Configuration
#define TIKTOK_GLOBAL @"com.zhiliaoapp.musically"
#define TIKTOK_CHINA @"com.ss.iphone.ugc.Aweme"
typedef int (*SBSLaunchAppFunc)(CFStringRef identifier, Boolean suspended);

@implementation AutomationManager {
  NSThread *_workerThread;
}

+ (instancetype)sharedManager {
  static AutomationManager *shared = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    shared = [[AutomationManager alloc] init];
    // Default Config
    shared.config = (TrollConfig){.startHour = 9,
                                  .endHour = 23,
                                  .minWatchSec = 3,
                                  .maxWatchSec = 8,
                                  .swipeJitter = 0.05,
                                  .isRunning = NO};
    init_touch_system(); // Initialize HID once
  });
  return shared;
}

- (void)log:(NSString *)format, ... {
  va_list args;
  va_start(args, format);
  NSString *msg = [[NSString alloc] initWithFormat:format arguments:args];
  va_end(args);

  // Print to console
  printf("%s\n", [msg UTF8String]);

  // Send to UI
  if (self.logHandler) {
    dispatch_async(dispatch_get_main_queue(), ^{
      self.logHandler(msg);
    });
  }
}

- (void)startAutomation {
  if (self.config.isRunning)
    return;

  self.config = (TrollConfig){.startHour = self.config.startHour,
                              .endHour = self.config.endHour,
                              .minWatchSec = self.config.minWatchSec,
                              .maxWatchSec = self.config.maxWatchSec,
                              .swipeJitter = self.config.swipeJitter,
                              .isRunning = YES};

  [self log:@"[*] Starting Automation Service..."];

  _workerThread = [[NSThread alloc] initWithTarget:self
                                          selector:@selector(automationLoop)
                                            object:nil];
  [_workerThread start];
}

- (void)stopAutomation {
  if (!self.config.isRunning)
    return;

  [self log:@"[*] Stopping Automation Service..."];

  // Update struct safely? It's a primitive struct copy, so we need to update
  // the property
  TrollConfig newConfig = self.config;
  newConfig.isRunning = NO;
  self.config = newConfig;

  [_workerThread cancel];
  _workerThread = nil;
}

- (BOOL)isRunning {
  return self.config.isRunning;
}

// --- Logic from main.m ---

- (void)launchTikTok {
  [self log:@"[*] Launching TikTok..."];
  void *handle = dlopen("/System/Library/PrivateFrameworks/"
                        "SpringBoardServices.framework/SpringBoardServices",
                        RTLD_LAZY);
  if (!handle)
    return;

  SBSLaunchAppFunc SBSLaunchApplicationWithIdentifier =
      (SBSLaunchAppFunc)dlsym(handle, "SBSLaunchApplicationWithIdentifier");
  if (SBSLaunchApplicationWithIdentifier) {
    SBSLaunchApplicationWithIdentifier((__bridge CFStringRef)TIKTOK_GLOBAL,
                                       false);
    [NSThread sleepForTimeInterval:1.0];
    SBSLaunchApplicationWithIdentifier((__bridge CFStringRef)TIKTOK_CHINA,
                                       false);
  }
  dlclose(handle);
}

- (void)performLike {
  [self log:@"[*] Liking (Double Tap)"];
  perform_touch(0.5, 0.5);
  usleep(100000);
  perform_touch(0.5, 0.5);
}

- (float)randFloat:(float)min max:(float)max {
  return min + ((float)arc4random() / UINT32_MAX) * (max - min);
}

- (void)performHumanSwipe {
  float jitter = self.config.swipeJitter;
  float startX = [self randFloat:0.5 - jitter max:0.5 + jitter];
  float startY = [self randFloat:0.7 - jitter max:0.8 + jitter];
  float endX = startX + [self randFloat:-0.1 max:0.1];
  float endY = [self randFloat:0.2 max:0.3];
  float duration = [self randFloat:0.12 max:0.18];

  [self log:@"[*] Swipe (%.2f, %.2f) -> (%.2f, %.2f)", startX, startY, endX,
            endY];
  perform_swipe(startX, startY, endX, endY, duration);
}

- (BOOL)isWorkingHour {
  NSDate *now = [NSDate date];
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSInteger hour = [calendar component:NSCalendarUnitHour fromDate:now];

  if (self.config.startHour <= self.config.endHour) {
    return (hour >= self.config.startHour && hour < self.config.endHour);
  } else {
    return (hour >= self.config.startHour || hour < self.config.endHour);
  }
}

- (void)automationLoop {
  [self launchTikTok];
  [NSThread sleepForTimeInterval:5.0];

  int count = 0;
  while (self.config.isRunning && ![[NSThread currentThread] isCancelled]) {
    if (![self isWorkingHour]) {
      [self log:@"[-] Outside working hours. Sleeping 5 mins..."];
      [NSThread sleepForTimeInterval:300];
      continue;
    }

    count++;
    [self log:@"\n--- Video #%d ---", count];

    // Random Watch
    int interval = self.config.maxWatchSec - self.config.minWatchSec;
    if (interval < 1)
      interval = 1;
    int watchTime = self.config.minWatchSec + (arc4random() % interval);
    [self log:@"[*] Watching %ds", watchTime];
    [NSThread sleepForTimeInterval:watchTime];

    if (!self.config.isRunning)
      break;

    // Like Chance
    if (arc4random() % 2 == 0) {
      [self performLike];
      [NSThread sleepForTimeInterval:[self randFloat:0.5 max:1.5]];
    }

    if (!self.config.isRunning)
      break;

    // Swipe
    [self performHumanSwipe];
    [NSThread sleepForTimeInterval:[self randFloat:1.0 max:2.0]];
  }

  [self log:@"[*] Automation Thread Stopped."];
}

@end
