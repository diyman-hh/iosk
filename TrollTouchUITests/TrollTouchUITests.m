//
//  TrollTouchUITests.m
//  TrollTouch UI Tests
//
//  XCTest-based TikTok automation
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// Forward declare XCTest classes - will be loaded at runtime
@interface XCTestCase : NSObject
@property(nonatomic, assign) BOOL continueAfterFailure;
- (void)setUp;
- (void)tearDown;
@end

@interface XCUIApplication : NSObject
- (instancetype)initWithBundleIdentifier:(NSString *)bundleIdentifier;
- (void)launch;
- (BOOL)exists;
- (id)coordinateWithNormalizedOffset:(CGVector)normalizedOffset;
@end

@interface XCUICoordinate : NSObject
- (void)tap;
- (void)pressForDuration:(NSTimeInterval)duration
    thenDragToCoordinate:(XCUICoordinate *)otherCoordinate;
@end

// Our test class
@interface TrollTouchUITests : XCTestCase
@property(nonatomic, strong) XCUIApplication *tiktok;
@property(nonatomic, assign) int videoCount;
@end

@implementation TrollTouchUITests

- (void)setUp {
  [super setUp];

  // Continue after failure
  self.continueAfterFailure = YES;

  // Initialize video counter
  self.videoCount = 0;

  NSLog(@"[TrollTouch] XCTest 自动化测试启动");
}

- (void)tearDown {
  NSLog(@"[TrollTouch] 测试结束，共处理 %d 个视频", self.videoCount);
  [super tearDown];
}

/**
 * 主测试方法：TikTok 自动化
 * 这个测试会持续运行，自动刷 TikTok
 */
- (void)testTikTokAutomation {
  // 配置参数
  int totalVideos = 100; // 总共处理多少个视频
  int minWatchSec = 3;   // 最少观看秒数
  int maxWatchSec = 8;   // 最多观看秒数
  int likeChance = 30;   // 点赞概率 (%)
  int followChance = 5;  // 关注概率 (%)

  // 启动 TikTok
  [self launchTikTok];

  // 等待 TikTok 完全启动
  sleep(5);

  NSLog(@"[*] 开始自动化，目标: %d 个视频", totalVideos);

  // 主循环
  for (int i = 0; i < totalVideos; i++) {
    self.videoCount = i + 1;

    NSLog(@"\n--- 视频 #%d ---", self.videoCount);

    // 随机观看时长
    int watchTime =
        minWatchSec + arc4random_uniform(maxWatchSec - minWatchSec + 1);
    NSLog(@"[*] 观看 %d 秒...", watchTime);
    sleep(watchTime);

    // 随机决定是否点赞
    if (arc4random_uniform(100) < likeChance) {
      [self performLike];
      sleep(1);
    }

    // 随机决定是否关注
    if (arc4random_uniform(100) < followChance) {
      [self performFollow];
      sleep(1);
    }

    // 滑动到下一个视频
    [self performSwipe];

    // 短暂延迟
    sleep(1);
  }

  NSLog(@"[*] 自动化完成！");
}

/**
 * 启动 TikTok
 */
- (void)launchTikTok {
  NSLog(@"[*] 正在启动 TikTok...");

  // 尝试国际版
  self.tiktok = [[XCUIApplication alloc]
      initWithBundleIdentifier:@"com.zhiliaoapp.musically"];
  [self.tiktok launch];

  // 如果国际版没有安装，尝试国内版
  if (!self.tiktok.exists) {
    NSLog(@"[*] 国际版未安装，尝试抖音...");
    self.tiktok = [[XCUIApplication alloc]
        initWithBundleIdentifier:@"com.ss.iphone.ugc.Aweme"];
    [self.tiktok launch];
  }

  XCTAssertTrue(self.tiktok.exists, @"TikTok/抖音 未安装");
}

/**
 * 执行点赞操作
 */
- (void)performLike {
  NSLog(@"[*] 执行点赞");

  // 点赞按钮通常在右侧中间偏下
  // 坐标: (0.93, 0.65) - 右侧，中间偏下
  XCUICoordinate *likeButton =
      [self.tiktok coordinateWithNormalizedOffset:CGVectorMake(0.93, 0.65)];

  // 双击以确保点赞（有时需要双击）
  [likeButton tap];
  usleep(100000); // 0.1秒
  [likeButton tap];
}

/**
 * 执行关注操作
 */
- (void)performFollow {
  NSLog(@"[*] 执行关注");

  // 关注按钮在头像旁边
  // 坐标: (0.93, 0.36) - 右侧，上方
  XCUICoordinate *followButton =
      [self.tiktok coordinateWithNormalizedOffset:CGVectorMake(0.93, 0.36)];

  [followButton tap];
}

/**
 * 执行滑动到下一个视频
 */
- (void)performSwipe {
  // 添加随机抖动，模拟人类行为
  float jitter = 0.05;
  float startX = 0.5 + ((arc4random_uniform(10) - 5) * jitter / 5.0);
  float startY = 0.75 + ((arc4random_uniform(10) - 5) * jitter / 5.0);
  float endX = 0.5 + ((arc4random_uniform(10) - 5) * jitter / 5.0);
  float endY = 0.25 + ((arc4random_uniform(10) - 5) * jitter / 5.0);

  NSLog(@"[*] 执行滑动: (%.2f, %.2f) -> (%.2f, %.2f)", startX, startY, endX,
        endY);

  XCUICoordinate *start =
      [self.tiktok coordinateWithNormalizedOffset:CGVectorMake(startX, startY)];
  XCUICoordinate *end =
      [self.tiktok coordinateWithNormalizedOffset:CGVectorMake(endX, endY)];

  // 滑动持续时间: 0.3秒
  [start pressForDuration:0.1 thenDragToCoordinate:end];
}

/**
 * 测试方法：单次点赞测试
 */
- (void)testSingleLike {
  [self launchTikTok];
  sleep(3);

  NSLog(@"[测试] 执行单次点赞");
  [self performLike];

  sleep(2);
}

/**
 * 测试方法：单次滑动测试
 */
- (void)testSingleSwipe {
  [self launchTikTok];
  sleep(3);

  NSLog(@"[测试] 执行单次滑动");
  [self performSwipe];

  sleep(2);
}

@end
