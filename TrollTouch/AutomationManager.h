#import <Foundation/Foundation.h>

// Configuration Structure
typedef struct {
  int startHour;     // e.g. 9
  int endHour;       // e.g. 23
  int minWatchSec;   // e.g. 3
  int maxWatchSec;   // e.g. 8
  float swipeJitter; // e.g. 0.05
  BOOL isRunning;
} TrollConfig;

@interface AutomationManager : NSObject

@property(nonatomic, assign) TrollConfig config;

+ (instancetype)sharedManager;

- (void)startAutomation;
- (void)stopAutomation;
- (BOOL)isRunning;
- (void)performFollow;     // 测试: 关注
- (void)performLike;       // 测试: 点赞
- (void)performHumanSwipe; // 测试: 下一个视频

// Log callback for UI
@property(nonatomic, copy) void (^logHandler)(NSString *log);

@end
