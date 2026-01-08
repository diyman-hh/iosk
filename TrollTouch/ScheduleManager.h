//
//  ScheduleManager.h
//  TrollTouch
//
//  Manage scheduled automation tasks
//

#import <Foundation/Foundation.h>

@interface ScheduleManager : NSObject

@property(nonatomic, assign) NSInteger startHour; // 开始时间（小时，0-23）
@property(nonatomic, assign) NSInteger endHour;   // 结束时间（小时，0-23）
@property(nonatomic, assign) BOOL isEnabled;      // 是否启用定时任务
@property(nonatomic, assign, readonly)
    BOOL isInWorkingHours; // 是否在工作时间内

+ (instancetype)sharedManager;

// Start schedule monitoring
- (void)startSchedule;

// Stop schedule monitoring
- (void)stopSchedule;

// Check if currently in working hours
- (BOOL)isInWorkingHours;

@end
