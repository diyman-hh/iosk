# 实施计划：TrollStore + XCTest 完美方案

## 阶段 1：清理和重构（立即开始）

### 1.1 移除失败的方案
- [ ] 删除 `BackboardTouchInjector.h/m`
- [ ] 删除 `BackboardServices.h`
- [ ] 删除 `TouchSimulator.c/h`
- [ ] 删除 `IOKit_Private.h`（或简化）
- [ ] 清理 `AutomationManager.m` 中的相关引用

### 1.2 更新 Makefile
```makefile
TrollTouch_FILES = \
    TrollTouch/main.m \
    TrollTouch/AppDelegate.m \
    TrollTouch/RootViewController.m \
    TrollTouch/AutomationManager.m \
    TrollTouch/XCTestRunner.m \
    TrollTouch/ScheduleManager.m

TrollTouch_FRAMEWORKS = UIKit CoreGraphics Foundation XCTest
```

## 阶段 2：实现 XCTest Runner（核心）

### 2.1 创建 XCTestRunner
```objectivec
// XCTestRunner.h
@interface XCTestRunner : NSObject
+ (void)runAutomationTest;
+ (void)stopAutomationTest;
@end

// XCTestRunner.m
+ (void)runAutomationTest {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *bundlePath = [[NSBundle mainBundle].bundlePath 
            stringByAppendingPathComponent:@"PlugIns/TrollTouchUITests.xctest"];
        
        NSBundle *testBundle = [NSBundle bundleWithPath:bundlePath];
        if (![testBundle load]) {
            NSLog(@"Failed to load test bundle");
            return;
        }
        
        Class testClass = NSClassFromString(@"TrollTouchUITests");
        XCTestSuite *suite = [XCTestSuite testSuiteForTestCaseClass:testClass];
        
        // 运行测试
        XCTestSuiteRun *run = [[XCTestSuiteRun alloc] initWithTest:suite];
        [suite performTest:run];
    });
}
```

### 2.2 更新 TrollTouchUITests
```objectivec
// 添加更多测试方法
- (void)testContinuousAutomation {
    // 持续运行，直到被停止
    while (self.shouldContinue) {
        [self performSingleCycle];
    }
}

- (void)performSingleCycle {
    // 观看视频
    sleep(arc4random_uniform(5) + 3);
    
    // 随机点赞
    if (arc4random_uniform(100) < 30) {
        [self performLike];
    }
    
    // 随机关注
    if (arc4random_uniform(100) < 5) {
        [self performFollow];
    }
    
    // 滑动到下一个视频
    [self performSwipe];
}
```

## 阶段 3：添加定时任务

### 3.1 创建 ScheduleManager
```objectivec
@interface ScheduleManager : NSObject
@property (nonatomic, assign) NSInteger startHour;
@property (nonatomic, assign) NSInteger endHour;
@property (nonatomic, assign) BOOL isEnabled;

- (void)startSchedule;
- (void)stopSchedule;
@end

@implementation ScheduleManager

- (void)startSchedule {
    // 检查当前时间
    NSDate *now = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSInteger hour = [calendar component:NSCalendarUnitHour fromDate:now];
    
    if (hour >= self.startHour && hour < self.endHour) {
        // 在工作时间内，立即启动
        [XCTestRunner runAutomationTest];
    }
    
    // 设置定时器，每小时检查一次
    [NSTimer scheduledTimerWithTimeInterval:3600 
                                     repeats:YES 
                                       block:^(NSTimer *timer) {
        [self checkAndRun];
    }];
}

- (void)checkAndRun {
    NSInteger hour = [[NSCalendar currentCalendar] 
        component:NSCalendarUnitHour fromDate:[NSDate date]];
    
    if (hour >= self.startHour && hour < self.endHour) {
        if (!self.isRunning) {
            [XCTestRunner runAutomationTest];
            self.isRunning = YES;
        }
    } else {
        if (self.isRunning) {
            [XCTestRunner stopAutomationTest];
            self.isRunning = NO;
        }
    }
}

@end
```

## 阶段 4：完善 UI

### 4.1 配置界面
```objectivec
// RootViewController.m
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 标题
    UILabel *title = ...;
    title.text = @"TikTok 自动化助手";
    
    // 时间设置
    UILabel *timeLabel = ...;
    timeLabel.text = @"工作时间：";
    
    UIDatePicker *startTimePicker = ...;
    UIDatePicker *endTimePicker = ...;
    
    // 功能开关
    UISwitch *autoLikeSwitch = ...;
    UISwitch *autoFollowSwitch = ...;
    UISwitch *autoCommentSwitch = ...;
    
    // 启动按钮
    UIButton *startButton = ...;
    [startButton setTitle:@"启动自动化" forState:UIControlStateNormal];
    [startButton addTarget:self 
                    action:@selector(startAutomation) 
          forControlEvents:UIControlEventTouchUpInside];
}
```

## 阶段 5：高级功能

### 5.1 评论功能
```objectivec
- (void)performComment {
    XCUIApplication *app = [[XCUIApplication alloc] 
        initWithBundleIdentifier:@"com.zhiliaoapp.musically"];
    
    // 点击评论按钮
    XCUIElement *commentButton = app.buttons[@"评论"];
    [commentButton tap];
    
    // 输入评论
    XCUIElement *textField = app.textFields.firstMatch;
    [textField tap];
    [textField typeText:@"太棒了！"];
    
    // 发送
    XCUIElement *sendButton = app.buttons[@"发送"];
    [sendButton tap];
}
```

### 5.2 发视频功能
```objectivec
- (void)postVideo {
    XCUIApplication *app = [[XCUIApplication alloc] 
        initWithBundleIdentifier:@"com.zhiliaoapp.musically"];
    
    // 点击发布按钮
    XCUIElement *postButton = app.buttons[@"发布"];
    [postButton tap];
    
    // 选择视频
    // ... 使用 XCUIElement 导航到相册
    
    // 添加描述
    XCUIElement *descField = app.textViews.firstMatch;
    [descField tap];
    [descField typeText:@"分享日常"];
    
    // 发布
    XCUIElement *publishButton = app.buttons[@"发布"];
    [publishButton tap];
}
```

## 时间估计

- 阶段 1（清理）：30 分钟
- 阶段 2（XCTest Runner）：1-2 小时
- 阶段 3（定时任务）：1 小时
- 阶段 4（UI）：1 小时
- 阶段 5（高级功能）：2-3 小时

**总计：5-8 小时**

## 立即开始？

我可以现在就开始实施：
1. 清理所有失败的代码
2. 实现 XCTest Runner
3. 添加定时功能
4. 完善 UI

你准备好了吗？我们开始吧！
