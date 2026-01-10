//
//  AccessibilityAutomator.h
//  TrollTouch
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AccessibilityAutomator : NSObject

+ (instancetype)sharedAutomator;

// 权限管理
- (BOOL)hasAccessibilityPermission;
- (void)requestAccessibilityPermission;

// 自动化控制
- (void)startAutoSwipe;
- (void)stopAutoSwipe;
- (BOOL)isRunning;

// 手势操作
- (void)performSwipeUp;
- (void)performSwipeDown;
- (void)performTapAtPoint:(CGPoint)point;

// 配置
@property(nonatomic, assign) NSTimeInterval swipeInterval; // 滑动间隔（秒）
@property(nonatomic, assign) NSTimeInterval swipeDuration; // 滑动持续时间（秒）

@end

NS_ASSUME_NONNULL_END
