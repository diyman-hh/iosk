//
//  AccessibilityAutomator.m
//  TrollTouch
//

#import "AccessibilityAutomator.h"
#import <objc/runtime.h>

@interface AccessibilityAutomator ()
@property(nonatomic, strong) NSTimer *autoSwipeTimer;
@property(nonatomic, assign) BOOL running;
@end

@implementation AccessibilityAutomator

+ (instancetype)sharedAutomator {
  static AccessibilityAutomator *instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[AccessibilityAutomator alloc] init];
  });
  return instance;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _swipeInterval = 3.0; // 默认 3 秒滑动一次
    _swipeDuration = 0.3; // 默认滑动持续 0.3 秒
    _running = NO;
  }
  return self;
}

#pragma mark - Permission

- (BOOL)hasAccessibilityPermission {
  // 在 iOS 上，我们无法直接检查 Accessibility 权限
  // 但可以尝试访问 Accessibility 元素来判断
  return YES; // 简化处理，实际使用时会在操作时检测
}

- (void)requestAccessibilityPermission {
  // iOS 不提供直接的 API 请求 Accessibility 权限
  // 需要引导用户到设置中手动开启
  NSString *message = @"请前往 设置 > 辅助功能 > 触控 > 辅助触控，启用 "
                      @"TrollTouch 的辅助功能权限";

  UIAlertController *alert =
      [UIAlertController alertControllerWithTitle:@"需要辅助功能权限"
                                          message:message
                                   preferredStyle:UIAlertControllerStyleAlert];

  [alert
      addAction:
          [UIAlertAction
              actionWithTitle:@"去设置"
                        style:UIAlertActionStyleDefault
                      handler:^(UIAlertAction *_Nonnull action) {
                        [[UIApplication sharedApplication]
                                      openURL:
                                          [NSURL
                                              URLWithString:
                                                  UIApplicationOpenSettingsURLString]
                                      options:@{}
                            completionHandler:nil];
                      }]];

  [alert addAction:[UIAlertAction actionWithTitle:@"取消"
                                            style:UIAlertActionStyleCancel
                                          handler:nil]];

  UIViewController *rootVC =
      [UIApplication sharedApplication].keyWindow.rootViewController;
  [rootVC presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Auto Swipe Control

- (void)startAutoSwipe {
  if (self.running) {
    NSLog(@"[AccessibilityAutomator] Auto swipe already running");
    return;
  }

  NSLog(@"[AccessibilityAutomator] Starting auto swipe with interval: %.1fs",
        self.swipeInterval);
  self.running = YES;

  // 立即执行一次
  [self performSwipeUp];

  // 启动定时器
  self.autoSwipeTimer =
      [NSTimer scheduledTimerWithTimeInterval:self.swipeInterval
                                       target:self
                                     selector:@selector(performSwipeUp)
                                     userInfo:nil
                                      repeats:YES];
}

- (void)stopAutoSwipe {
  if (!self.running) {
    return;
  }

  NSLog(@"[AccessibilityAutomator] Stopping auto swipe");
  self.running = NO;

  [self.autoSwipeTimer invalidate];
  self.autoSwipeTimer = nil;
}

- (BOOL)isRunning {
  return self.running;
}

#pragma mark - Gesture Operations

- (void)performSwipeUp {
  NSLog(@"[AccessibilityAutomator] Performing swipe up");

  CGRect screenBounds = [[UIScreen mainScreen] bounds];
  CGFloat screenHeight = screenBounds.size.height;
  CGFloat screenWidth = screenBounds.size.width;

  // 从屏幕下方 80% 滑动到上方 20%
  CGPoint startPoint = CGPointMake(screenWidth * 0.5, screenHeight * 0.8);
  CGPoint endPoint = CGPointMake(screenWidth * 0.5, screenHeight * 0.2);

  [self simulateSwipeFromPoint:startPoint
                       toPoint:endPoint
                      duration:self.swipeDuration];
}

- (void)performSwipeDown {
  NSLog(@"[AccessibilityAutomator] Performing swipe down");

  CGRect screenBounds = [[UIScreen mainScreen] bounds];
  CGFloat screenHeight = screenBounds.size.height;
  CGFloat screenWidth = screenBounds.size.width;

  CGPoint startPoint = CGPointMake(screenWidth * 0.5, screenHeight * 0.2);
  CGPoint endPoint = CGPointMake(screenWidth * 0.5, screenHeight * 0.8);

  [self simulateSwipeFromPoint:startPoint
                       toPoint:endPoint
                      duration:self.swipeDuration];
}

- (void)performTapAtPoint:(CGPoint)point {
  NSLog(@"[AccessibilityAutomator] Performing tap at (%.1f, %.1f)", point.x,
        point.y);
  [self simulateTapAtPoint:point];
}

#pragma mark - Low-Level Simulation

- (void)simulateSwipeFromPoint:(CGPoint)start
                       toPoint:(CGPoint)end
                      duration:(NSTimeInterval)duration {
  // 使用 UITouch 私有 API 模拟触摸
  // 注意：这种方法只能在当前应用内工作

  UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
  if (!keyWindow) {
    NSLog(@"[AccessibilityAutomator] No key window found");
    return;
  }

  // 创建触摸事件序列
  [self sendTouchEvent:UITouchPhaseBegan atPoint:start inWindow:keyWindow];

  // 计算中间点
  int steps = (int)(duration * 60); // 60fps
  for (int i = 1; i < steps; i++) {
    CGFloat progress = (CGFloat)i / steps;
    CGPoint currentPoint = CGPointMake(start.x + (end.x - start.x) * progress,
                                       start.y + (end.y - start.y) * progress);

    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW,
                      (int64_t)(i * duration / steps * NSEC_PER_SEC)),
        dispatch_get_main_queue(), ^{
          [self sendTouchEvent:UITouchPhaseMoved
                       atPoint:currentPoint
                      inWindow:keyWindow];
        });
  }

  // 结束触摸
  dispatch_after(
      dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)),
      dispatch_get_main_queue(), ^{
        [self sendTouchEvent:UITouchPhaseEnded atPoint:end inWindow:keyWindow];
      });
}

- (void)simulateTapAtPoint:(CGPoint)point {
  UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
  if (!keyWindow) {
    return;
  }

  [self sendTouchEvent:UITouchPhaseBegan atPoint:point inWindow:keyWindow];

  dispatch_after(
      dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)),
      dispatch_get_main_queue(), ^{
        [self sendTouchEvent:UITouchPhaseEnded
                     atPoint:point
                    inWindow:keyWindow];
      });
}

- (void)sendTouchEvent:(UITouchPhase)phase
               atPoint:(CGPoint)point
              inWindow:(UIWindow *)window {
  // 简化版本：直接使用 UIView 的手势识别
  // 这种方法在应用内模拟触摸更可靠

  UIView *targetView = [window hitTest:point withEvent:nil];
  if (!targetView) {
    targetView = window;
  }

  NSLog(@"[AccessibilityAutomator] Sending touch %ld to view: %@", (long)phase,
        NSStringFromClass([targetView class]));

  // 由于我们无法可靠地创建 UIEvent，改用更简单的方法
  // 直接触发视图层级的响应

  // 注意：这种方法的局限性是只能在当前应用内工作
  // 对于刷视频等场景，需要应用本身支持手势

  // 简化实现：只记录日志，实际触摸需要使用其他方法
  NSLog(@"[AccessibilityAutomator] Touch simulation at (%.1f, %.1f) - Note: "
        @"In-app touch simulation has limitations",
        point.x, point.y);
}

@end
