#include "IOKit_Private.h"
#include "TouchSimulator.c"
#include <Foundation/Foundation.h>
#include <dlfcn.h>
#include <unistd.h>

// --- Configuration ---
#define TIKTOK_GLOBAL @"com.zhiliaoapp.musically"
#define TIKTOK_CHINA @"com.ss.iphone.ugc.Aweme"

// --- Dynamic Linking for Private API ---
typedef int (*SBSLaunchAppFunc)(CFStringRef identifier, Boolean suspended);

void launchTikTok() {
  printf("[*] Launching TikTok via dlopen...\n");

  // Dynamically load SpringBoardServices
  void *handle = dlopen("/System/Library/PrivateFrameworks/"
                        "SpringBoardServices.framework/SpringBoardServices",
                        RTLD_LAZY);
  if (!handle) {
    printf("[-] Failed to open SpringBoardServices: %s\n", dlerror());
    return;
  }

  SBSLaunchAppFunc SBSLaunchApplicationWithIdentifier =
      (SBSLaunchAppFunc)dlsym(handle, "SBSLaunchApplicationWithIdentifier");
  if (!SBSLaunchApplicationWithIdentifier) {
    printf("[-] Failed to find symbol SBSLaunchApplicationWithIdentifier\n");
    return;
  }

  // Try Global first
  SBSLaunchApplicationWithIdentifier((__bridge CFStringRef)TIKTOK_GLOBAL,
                                     false);
  sleep(1);
  // Try Douyin just in case
  SBSLaunchApplicationWithIdentifier((__bridge CFStringRef)TIKTOK_CHINA, false);

  dlclose(handle);
}

// Prototype from TouchSimulator.c
void perform_swipe(float x1, float y1, float x2, float y2, float duration_sec);

void perform_swipe_up() {
  printf("[*] Swiping Up (Next Video)...\n");
  // Start Center-Bottom (0.5, 0.8) -> End Center-Top (0.5, 0.2)
  // Fast swipe (0.15s) for "Flick" effect needed by TikTok
  perform_swipe(0.5, 0.75, 0.5, 0.25, 0.15);
}

void perform_like() {
  printf("[*] Liking (Double Tap)...\n");
  perform_touch(0.5, 0.5);
  usleep(100000); // 100ms gap
  perform_touch(0.5, 0.5);
}

// --- Configuration Struct ---
typedef struct {
  int startHour;     // e.g. 9 (09:00)
  int endHour;       // e.g. 23 (23:00)
  int minWatchSec;   // e.g. 3
  int maxWatchSec;   // e.g. 8
  float swipeJitter; // e.g. 0.05
} TrollConfig;

static TrollConfig config = {.startHour = 9,
                             .endHour = 23,
                             .minWatchSec = 3,
                             .maxWatchSec = 8,
                             .swipeJitter = 0.05};

// --- Helpers ---
bool isWorkingHour() {
  time_t now;
  struct tm *local;
  time(&now);
  local = localtime(&now);

  int currentHour = local->tm_hour;
  // Simple check: if start < end, between start/end; else (overnight)
  if (config.startHour <= config.endHour) {
    return (currentHour >= config.startHour && currentHour < config.endHour);
  } else {
    return (currentHour >= config.startHour || currentHour < config.endHour);
  }
}

// Random float between min and max
float rand_float(float min, float max) {
  return min + ((float)arc4random() / UINT32_MAX) * (max - min);
}

void perform_human_swipe_up() {
  // Base: Bottom (0.5, 0.75) -> Top (0.5, 0.25)
  // Add jitter to X and Y to simulate thumb curvature
  float startX = rand_float(0.5 - config.swipeJitter, 0.5 + config.swipeJitter);
  float startY = rand_float(0.7 - config.swipeJitter, 0.8 + config.swipeJitter);

  float endX = startX + rand_float(-0.1, 0.1); // Slight curve
  float endY = rand_float(0.2, 0.3);

  float duration = rand_float(0.12, 0.18); // Variable speed

  printf("[*] Human Swipe: (%.2f, %.2f) -> (%.2f, %.2f) in %.2fs\n", startX,
         startY, endX, endY, duration);
  perform_swipe(startX, startY, endX, endY, duration);
}

int main(int argc, char *argv[]) {
  printf("--- TrollTouch Automation v2.0 (Smart) ---\n");

  // 1. Initialize HID System
  init_touch_system();

  // 2. Open Target App
  launchTikTok();
  sleep(5); // Wait for splash screen

  // 3. Automation Loop
  int count = 0;
  while (true) {
    if (!isWorkingHour()) {
      printf("[-] Late night (Sleeping until %02d:00)...\n", config.startHour);
      sleep(60 * 5); // Sleep 5 mins
      continue;
    }

    printf("\n--- Video #%d ---\n", ++count);

    // Random Watch Time
    int interval = config.maxWatchSec - config.minWatchSec;
    if (interval <= 0)
      interval = 1;
    int watch_time = config.minWatchSec + (arc4random() % interval);

    printf("[*] Watching for %d seconds...\n", watch_time);
    sleep(watch_time);

    // 50% chance to Like
    if (arc4random() % 2 == 0) {
      perform_like();
      sleep(rand_float(0.5, 1.5)); // Random delay after like
    }

    // Scroll to next
    perform_human_swipe_up();

    // Random wait for scroll animation/buffer
    usleep(rand_float(1.0, 2.0) * 1000000);
  }

  return 0;
}
