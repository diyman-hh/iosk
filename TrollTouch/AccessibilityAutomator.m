//
//  AccessibilityAutomator.m
//  TrollTouch
//

#import "AccessibilityAutomator.h"
#import <XCTest/XCTest.h>

@interface AccessibilityAutomator ()
@property(nonatomic, strong) NSTimer *autoSwipeTimer;
@property(nonatomic, assign) BOOL running;
@property(nonatomic, strong) XCUIApplication *app;
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
    _swipeInterval = 3.0;
    _swipeDuration = 0.3;
    _running = NO;

    // 初始化 XCUIApplication
    _app = [[XCUIApplication alloc] init];
  }
  return self;
}

#pragma mark - Permission

- (BOOL)hasAccessibilityPermission {
  return YES;
}

- (void)requestAccessibilityPermission {
  NSString *message = @"此功能使用 XCTest 框架模拟触摸，无需额外权限";

  UIAlertController *alert =
      [UIAlertController alertControllerWithTitle:@"提示"
                                          message:message
                                   preferredStyle:UIAlertControllerStyleAlert];

  [alert addAction:[UIAlertAction actionWithTitle:@"确定"
                                            style:UIAlertActionStyleDefault
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

  NSLog(@"[AccessibilityAutomator] Starting auto swipe with XCTest framework");
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
  NSLog(@"[AccessibilityAutomator] Performing swipe up with XCTest");

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
  NSLog(@"[AccessibilityAutomator] Performing swipe down with XCTest");

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
  NSLog(@"[AccessibilityAutomator] Performing tap at (%.1f, %.1f) with XCTest",
        point.x, point.y);
  [self simulateTapAtPoint:point];
}

#pragma mark - XCTest-Based Simulation

- (void)simulateSwipeFromPoint:(CGPoint)start
                       toPoint:(CGPoint)end
                      duration:(NSTimeInterval)duration {
  @try {
    // 使用 XCUICoordinate 创建坐标
    CGRect screenBounds = [[UIScreen mainScreen] bounds];

    // 转换为归一化坐标 (0-1)
    CGFloat normalizedStartX = start.x / screenBounds.size.width;
    CGFloat normalizedStartY = start.y / screenBounds.size.height;
    CGFloat normalizedEndX = end.x / screenBounds.size.width;
    CGFloat normalizedEndY = end.y / screenBounds.size.height;

    NSLog(@"[AccessibilityAutomator] Swipe from (%.3f, %.3f) to (%.3f, %.3f)",
          normalizedStartX, normalizedStartY, normalizedEndX, normalizedEndY);

    // 创建起始和结束坐标
    XCUICoordinate *startCoordinate = [self.app
        coordinateWithNormalizedOffset:CGVectorMake(normalizedStartX,
                                                    normalizedStartY)];
    XCUICoordinate *endCoordinate =
        [self.app coordinateWithNormalizedOffset:CGVectorMake(normalizedEndX,
                                                              normalizedEndY)];

    // 执行滑动
    [startCoordinate pressForDuration:0.1 thenDragToCoordinate:endCoordinate];

    NSLog(@"[AccessibilityAutomator] ✅ Swipe executed successfully");
  } @catch (NSException *exception) {
    NSLog(@"[AccessibilityAutomator] ❌ Swipe failed: %@", exception.reason);
  }
}

- (void)simulateTapAtPoint:(CGPoint)point {
  @try {
    CGRect screenBounds = [[UIScreen mainScreen] bounds];

    // 转换为归一化坐标
    CGFloat normalizedX = point.x / screenBounds.size.width;
    CGFloat normalizedY = point.y / screenBounds.size.height;

    NSLog(@"[AccessibilityAutomator] Tap at (%.3f, %.3f)", normalizedX,
          normalizedY);

    // 创建坐标并点击
    XCUICoordinate *coordinate = [self.app
        coordinateWithNormalizedOffset:CGVectorMake(normalizedX, normalizedY)];
    [coordinate tap];

    NSLog(@"[AccessibilityAutomator] ✅ Tap executed successfully");
  } @catch (NSException *exception) {
    NSLog(@"[AccessibilityAutomator] ❌ Tap failed: %@", exception.reason);
  }
}

@end
