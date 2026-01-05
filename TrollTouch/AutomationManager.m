#import "AutomationManager.h"
#import "IOKit_Private.h"
#import "ScreenCapture.h"
#include "TouchSimulator.c"
#import "VisionHelper.h"
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
    shared.config = (TrollConfig){.startHour = 9,
                                  .endHour = 23,
                                  .minWatchSec = 3,
                                  .maxWatchSec = 8,
                                  .swipeJitter = 0.05,
                                  .isRunning = NO};
    init_touch_system();
  });
  return shared;
}

- (void)log:(NSString *)format, ... {
  va_list args;
  va_start(args, format);
  NSString *msg = [[NSString alloc] initWithFormat:format arguments:args];
  va_end(args);

  printf("%s\n", [msg UTF8String]);

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

  TrollConfig newConfig = self.config;
  newConfig.isRunning = NO;
  self.config = newConfig;

  [_workerThread cancel];
  _workerThread = nil;
}

- (BOOL)isRunning {
  return self.config.isRunning;
}

// --- Logic ---

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

// Feature 6: Auto Publish Macro
- (void)performAutoPublish {
  [self log:@"[*] --- Starting Auto-Publish ---"];

  // 1. Tap '+' (Center Bottom)
  // Coords approx: 0.5, 0.93
  [self log:@"[*] Tapping '+'..."];
  perform_touch(0.5, 0.93);
  [NSThread sleepForTimeInterval:2.5];

  // 2. Tap 'Upload' (Bottom Right)
  // Coords approx: 0.85, 0.85
  [self log:@"[*] Tapping Upload..."];
  perform_touch(0.85, 0.85);
  [NSThread sleepForTimeInterval:2.5];

  // 3. Select 1st Video (Top Left)
  // Coords approx: 0.16, 0.20
  [self log:@"[*] Selecting Video..."];
  perform_touch(0.16, 0.20);
  [NSThread sleepForTimeInterval:1.5];

  // 4. Tap Next (Bottom Right)
  [self log:@"[*] Tapping Next..."];
  perform_touch(0.85, 0.93);
  [NSThread sleepForTimeInterval:4.0];

  // 5. Tap Next (Edit Page)
  [self log:@"[*] Tapping Next (Edit)..."];
  perform_touch(0.85, 0.93);
  [NSThread sleepForTimeInterval:3.0];

  // 6. Tap Post
  [self log:@"[*] Tapping POST!"];
  perform_touch(0.85, 0.93);
  [NSThread sleepForTimeInterval:5.0];

  [self log:@"[*] Auto-Publish Done."];

  // Return to feed (Tap Home bottom left)
  perform_touch(0.08, 0.93);
  [NSThread sleepForTimeInterval:2.0];
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

    // --- Feature: State Detection ---
    UIImage *screen = captureScreen();
    if (screen) {
      BOOL isFeed = isVideoFeed(screen);
      if (!isFeed) {
        [self log:@"[!] Warning: Visual check suggests we are NOT on Video "
                  @"Feed."];
      }
    }

    count++;
    [self log:@"\n--- Video #%d ---", count];

    // --- Feature: Auto Publish (Every 50 videos) ---
    if (count % 50 == 0) {
      [self performAutoPublish];
      continue; // Skip the rest of the loop
    }

    // --- Feature: OCR Stats (Every 15 videos) ---
    if (count % 15 == 0) {
      [self log:@"[*] Checking Profile Stats (OCR)..."];
      // Swipe Left
      perform_swipe(0.8, 0.5, 0.2, 0.5, 0.3);
      [NSThread sleepForTimeInterval:2.0];

      UIImage *profileImg = captureScreen();
      if (profileImg) {
        recognizeText(profileImg, ^(NSString *res) {
          if (res) {
            // Sanitize newlines
            NSString *log = [res stringByReplacingOccurrencesOfString:@"\n"
                                                           withString:@" | "];
            if (log.length > 60)
              log = [log substringToIndex:60];
            [self log:@"[OCR] Found: %@", log];
          }
        });
      }
      // Swipe Right Back
      [NSThread sleepForTimeInterval:2.0];
      perform_swipe(0.2, 0.5, 0.8, 0.5, 0.3);
    }

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
