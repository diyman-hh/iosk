//
//  ScheduleManager.m
//  TrollTouch
//
//  Manage scheduled automation tasks
//

#import "ScheduleManager.h"
#import "XCTestRunner.h"
#import <UserNotifications/UserNotifications.h>

@implementation ScheduleManager {
  NSTimer *_checkTimer;
}

+ (instancetype)sharedManager {
  static ScheduleManager *instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[self alloc] init];
  });
  return instance;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    // Default working hours: 0 - 24 (24/7)
    _startHour = 0;
    _endHour = 24;
    _isEnabled = NO;
  }
  return self;
}

- (void)startSchedule {
  if (!self.isEnabled) {
    NSLog(@"[ScheduleManager] Schedule is disabled");
    return;
  }

  NSLog(@"[ScheduleManager] Starting schedule monitoring");
  NSLog(@"[ScheduleManager] Working hours: %ld:00 - %ld:00",
        (long)self.startHour, (long)self.endHour);

  // Check immediately
  [self checkAndRun];

  // Set up timer to check every hour
  _checkTimer = [NSTimer scheduledTimerWithTimeInterval:3600.0 // 1 hour
                                                repeats:YES
                                                  block:^(NSTimer *timer) {
                                                    [self checkAndRun];
                                                  }];

  // Also check every 5 minutes for more responsive behavior
  [NSTimer scheduledTimerWithTimeInterval:300.0 // 5 minutes
                                  repeats:YES
                                    block:^(NSTimer *timer) {
                                      [self checkAndRun];
                                    }];
}

- (void)stopSchedule {
  NSLog(@"[ScheduleManager] Stopping schedule monitoring");

  if (_checkTimer) {
    [_checkTimer invalidate];
    _checkTimer = nil;
  }

  // Stop any running automation
  if ([XCTestRunner isRunning]) {
    [XCTestRunner stopAutomation];
  }
}

- (void)checkAndRun {
  BOOL inWorkingHours = [self isInWorkingHours];
  BOOL isRunning = [XCTestRunner isRunning];

  NSLog(@"[ScheduleManager] Check: inWorkingHours=%d, isRunning=%d",
        inWorkingHours, isRunning);

  if (inWorkingHours && !isRunning) {
    NSLog(@"[ScheduleManager] ✅ Starting automation (in working hours)");
    [XCTestRunner startAutomation];

    // Send notification
    [self sendNotification:@"TrollTouch 已启动" body:@"自动化任务开始运行"];
  } else if (!inWorkingHours && isRunning) {
    NSLog(@"[ScheduleManager] ⏹ Stopping automation (outside working hours)");
    [XCTestRunner stopAutomation];

    // Send notification
    [self sendNotification:@"TrollTouch 已停止" body:@"已超出工作时间"];
  }
}

- (BOOL)isInWorkingHours {
  NSDate *now = [NSDate date];
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSInteger currentHour = [calendar component:NSCalendarUnitHour fromDate:now];

  // Check if current hour is within working hours
  if (self.startHour <= self.endHour) {
    // Normal case: e.g., 9:00 - 18:00
    return currentHour >= self.startHour && currentHour < self.endHour;
  } else {
    // Overnight case: e.g., 22:00 - 6:00
    return currentHour >= self.startHour || currentHour < self.endHour;
  }
}

- (void)sendNotification:(NSString *)title body:(NSString *)body {
  UNMutableNotificationContent *content =
      [[UNMutableNotificationContent alloc] init];
  content.title = title;
  content.body = body;
  content.sound = [UNNotificationSound defaultSound];

  UNNotificationRequest *request =
      [UNNotificationRequest requestWithIdentifier:[[NSUUID UUID] UUIDString]
                                           content:content
                                           trigger:nil];

  [[UNUserNotificationCenter currentNotificationCenter]
      addNotificationRequest:request
       withCompletionHandler:^(NSError *error) {
         if (error) {
           NSLog(@"[ScheduleManager] Notification error: %@", error);
         }
       }];
}

@end
