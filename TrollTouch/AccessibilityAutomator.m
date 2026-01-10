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
  // 使用 UIEvent 私有 API 创建触摸事件
  // 这种方法可以在应用内模拟触摸

  UIView *targetView = [window hitTest:point withEvent:nil];
  if (!targetView) {
    targetView = window;
  }

  // 创建 UITouch 对象（使用运行时）
  Class touchClass = NSClassFromString(@"UITouch");
  UITouch *touch = [[touchClass alloc] init];

  // 设置触摸属性
  [touch setValue:@(phase) forKey:@"phase"];
  [touch setValue:window forKey:@"window"];
  [touch setValue:targetView forKey:@"view"];
  [touch setValue:[NSValue valueWithCGPoint:point] forKey:@"locationInWindow"];
  [touch setValue:@(1) forKey:@"tapCount"];

  // 创建 UIEvent
  UIEvent *event = [[UIEvent alloc] init];
  [event setValue:@(UIEventTypeTouches) forKey:@"type"];
  [event setValue:[NSSet setWithObject:touch] forKey:@"allTouches"];

  // 发送事件
  switch (phase) {
  case UITouchPhaseBegan:
    [targetView touchesBegan:[NSSet setWithObject:touch] withEvent:event];
    break;
  case UITouchPhaseMoved:
    [targetView touchesMoved:[NSSet setWithObject:touch] withEvent:event];
    break;
  case UITouchPhaseEnded:
    [targetView touchesEnded:[NSSet setWithObject:touch] withEvent:event];
    break;
  default:
    break;
  }
}

@end
