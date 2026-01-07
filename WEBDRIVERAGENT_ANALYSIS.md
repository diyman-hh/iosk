# WebDriverAgent 方案分析

## 为什么 WebDriverAgent 可以后台控制其他应用？

### 核心原因

WebDriverAgent (WDA) 使用 **Apple 官方的 XCTest 框架**，这是一个专门用于 UI 自动化测试的框架，具有以下特权：

1. **测试进程权限**：XCTest 运行在独立的测试进程中，有系统级权限
2. **跨应用控制**：可以启动、控制任何应用（只要有 Bundle ID）
3. **UI 元素访问**：可以访问应用的完整 UI 树
4. **触摸注入**：使用 `XCUICoordinate.tap()` 等高级 API

### 技术对比

#### TrollTouch (当前实现)
```objectivec
// 使用 IOHIDEventSystemClient (私有 API)
IOHIDEventRef event = IOHIDEventCreateDigitizerEvent(...);
IOHIDEventSystemClientDispatchEvent(client, event);

// 问题：
// - 后台应用无法向前台应用注入事件
// - 需要应用保持前台
// - iOS 安全机制阻止
```

#### WebDriverAgent
```objectivec
// 使用 XCTest 框架 (官方 API)
#import <XCTest/XCTest.h>

XCUIApplication *app = [[XCUIApplication alloc] 
    initWithBundleIdentifier:@"com.zhiliaoapp.musically"];
[app launch];

// 坐标点击
XCUICoordinate *coord = [app coordinateWithNormalizedOffset:
    CGVectorMake(0.5, 0.5)];
[coord tap];

// 滑动
XCUICoordinate *start = [app coordinateWithNormalizedOffset:
    CGVectorMake(0.5, 0.8)];
XCUICoordinate *end = [app coordinateWithNormalizedOffset:
    CGVectorMake(0.5, 0.2)];
[start pressForDuration:0.1 thenDragToCoordinate:end];

// 优势：
// ✅ 可以后台运行
// ✅ 跨应用控制
// ✅ 不需要前台
// ✅ 官方支持
```

## 如何将 TrollTouch 改为基于 XCTest？

### 方案概述

将 TrollTouch 从普通应用改为 **XCTest UI Testing Bundle**。

### 架构变更

#### 当前架构
```
TrollTouch.app (普通应用)
├── AutomationManager.m
├── TouchSimulator.c (IOHIDEvent)
└── RootViewController.m
```

#### 新架构 (基于 XCTest)
```
TrollTouch.app (宿主应用)
└── TrollTouchUITests.xctest (测试 Bundle)
    ├── TrollTouchUITests.m (XCTestCase)
    ├── AutomationRunner.m (使用 XCUIApplication)
    └── Config.plist
```

### 实现步骤

#### 1. 创建 XCTest Target

```makefile
# Makefile
XCTEST_NAME = TrollTouchUITests
XCTEST_FILES = TrollTouchUITests.m AutomationRunner.m
XCTEST_FRAMEWORKS = XCTest

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/xctest.mk
```

#### 2. 实现测试用例

```objectivec
// TrollTouchUITests.m
#import <XCTest/XCTest.h>

@interface TrollTouchUITests : XCTestCase
@end

@implementation TrollTouchUITests

- (void)testTikTokAutomation {
    // 启动 TikTok
    XCUIApplication *tiktok = [[XCUIApplication alloc] 
        initWithBundleIdentifier:@"com.zhiliaoapp.musically"];
    [tiktok launch];
    
    // 等待启动
    sleep(3);
    
    // 自动化循环
    for (int i = 0; i < 100; i++) {
        NSLog(@"视频 #%d", i + 1);
        
        // 观看 3-8 秒
        int watchTime = 3 + arc4random_uniform(6);
        sleep(watchTime);
        
        // 随机操作
        int action = arc4random_uniform(10);
        
        if (action < 3) {
            // 30% 概率点赞
            [self performLike:tiktok];
        }
        
        // 滑动到下一个视频
        [self performSwipe:tiktok];
        
        sleep(1);
    }
}

- (void)performLike:(XCUIApplication *)app {
    // 点赞按钮位置（右侧中间偏下）
    XCUICoordinate *likeButton = [app 
        coordinateWithNormalizedOffset:CGVectorMake(0.93, 0.65)];
    [likeButton tap];
    NSLog(@"点赞");
}

- (void)performSwipe:(XCUIApplication *)app {
    // 从下往上滑动
    float startY = 0.75 + (arc4random_uniform(10) - 5) / 100.0;
    float endY = 0.25 + (arc4random_uniform(10) - 5) / 100.0;
    
    XCUICoordinate *start = [app 
        coordinateWithNormalizedOffset:CGVectorMake(0.5, startY)];
    XCUICoordinate *end = [app 
        coordinateWithNormalizedOffset:CGVectorMake(0.5, endY)];
    
    [start pressForDuration:0.1 thenDragToCoordinate:end];
    NSLog(@"滑动");
}

@end
```

#### 3. 运行方式

```bash
# 使用 xcodebuild 运行测试
xcodebuild test \
    -project TrollTouch.xcodeproj \
    -scheme TrollTouchUITests \
    -destination 'platform=iOS,id=<DEVICE_UDID>'

# 或者使用 xcrun
xcrun xctrace record \
    --template 'UI Automation' \
    --device <DEVICE_UDID> \
    --output automation.trace
```

### 优势

1. ✅ **真正的后台运行**：测试可以在后台执行
2. ✅ **跨应用控制**：可以控制任何应用
3. ✅ **官方支持**：使用 Apple 官方 API
4. ✅ **稳定可靠**：不依赖私有 API
5. ✅ **无需前台**：TrollTouch 不需要保持前台

### 劣势

1. ⚠️ **需要开发者证书**：必须有有效的开发者账号
2. ⚠️ **运行方式复杂**：需要通过 xcodebuild 或 Xcode 启动
3. ⚠️ **不是独立应用**：是测试 Bundle，不是普通应用
4. ⚠️ **Theos 支持有限**：Theos 对 XCTest 的支持不完善

## 推荐方案

### 选项 A：使用现有的 WebDriverAgent

直接使用 WebDriverAgent，通过 HTTP API 控制：

```python
# Python 脚本控制 TikTok
import requests

wda_url = "http://localhost:8100"

# 启动 TikTok
requests.post(f"{wda_url}/session", json={
    "capabilities": {
        "bundleId": "com.zhiliaoapp.musically"
    }
})

# 点击
requests.post(f"{wda_url}/session/1/wda/tap/0", json={
    "x": 350,
    "y": 600
})

# 滑动
requests.post(f"{wda_url}/session/1/wda/dragfromtoforduration", json={
    "fromX": 200,
    "fromY": 600,
    "toX": 200,
    "toY": 200,
    "duration": 0.3
})
```

### 选项 B：重写 TrollTouch 为 XCTest Bundle

完全重构项目，基于 XCTest 实现。

### 选项 C：继续使用当前方案（前台透明模式）

接受前台运行的限制。

## 我的建议

**如果你想要真正的后台自动化**，最实际的方案是：

1. **使用 WebDriverAgent**：
   - 已经成熟稳定
   - 有完整的文档和社区支持
   - 可以通过 HTTP API 控制
   - 配合 Python/Node.js 脚本使用

2. **或者重写为 XCTest**：
   - 如果你想要一个独立的解决方案
   - 需要投入较多时间重构
   - 但可以获得最佳的后台控制能力

你想选择哪个方向？我可以帮你：
- A. 集成 WebDriverAgent
- B. 重写为 XCTest Bundle
- C. 继续测试当前的前台透明模式
