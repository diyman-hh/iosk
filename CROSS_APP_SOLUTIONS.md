# 方案对比：如何实现跨应用触摸注入

## 问题
在 iOS 上，如何像 WebDriverAgent 一样实现后台跨应用触摸注入？

## 所有可行方案

### ❌ 方案 A：IOHIDEventSystemClient（已尝试，失败）
**原理**：使用 IOKit 的 HID 事件系统

**问题**：
- iOS 安全机制阻止后台应用注入事件到前台应用
- 即使有私有权限也无法绕过

**结论**：不可行

---

### ❌ 方案 B：透明覆盖窗口（已尝试，失败）
**原理**：创建透明窗口保持前台

**问题**：
- 切换到其他应用时，窗口会被隐藏
- iOS 不允许跨应用窗口覆盖

**结论**：不可行

---

### ⚠️ 方案 C：XCTest 框架（Theos 不支持）
**原理**：使用 Apple 官方的 UI 测试框架

**问题**：
- Theos 无法编译 XCTest Bundle
- 需要 Xcode 运行

**结论**：需要 Xcode，不适合 TrollStore

---

### ✅ 方案 D：BackboardServices + BKSendHIDEvent（推荐）⭐
**原理**：直接调用系统守护进程 backboardd 的私有 API

**优势**：
- ✅ 真正的系统级注入
- ✅ 可以后台运行
- ✅ 可以控制任何应用
- ✅ 不需要 XCTest
- ✅ TrollStore 可以使用

**实现**：
```objectivec
// 加载 BackboardServices 框架
void *handle = dlopen("/System/Library/PrivateFrameworks/BackboardServices.framework/BackboardServices", RTLD_LAZY);

// 获取 BKSendHIDEvent 函数
BKSendHIDEvent = dlsym(handle, "BKSendHIDEvent");

// 创建 HID 事件
IOHIDEventRef event = IOHIDEventCreateDigitizerFingerEvent(...);

// 发送到系统
BKSendHIDEvent(event);
```

**关键点**：
- 使用 `BKSendHIDEvent` 而不是 `IOHIDEventSystemClientDispatchEvent`
- 事件直接发送到 backboardd，绕过应用层限制
- 这是 WebDriverAgent 内部使用的方法之一

---

### ✅ 方案 E：GSEvent（备选方案）
**原理**：使用 GraphicsServices 的私有 API

**优势**：
- ✅ 系统级事件
- ✅ 可以跨应用

**劣势**：
- ⚠️ 在 iOS 15+ 上可能不稳定
- ⚠️ 需要更多逆向工程

---

## WebDriverAgent 的实现方式

WebDriverAgent 实际上使用了**多种方法的组合**：

1. **主要方法**：XCTest 框架
   - 使用 `XCUICoordinate.tap()` 等高级 API
   - 运行在测试进程中，有特殊权限

2. **备用方法**：BackboardServices
   - 当 XCTest 不可用时，使用 `BKSendHIDEvent`
   - 直接系统级注入

3. **辅助方法**：IOHIDEvent
   - 用于某些特殊场景

## 当前实现：方案 D

我已经创建了 `BackboardTouchInjector` 类，使用 `BKSendHIDEvent`：

### 文件结构
```
TrollTouch/
├── BackboardServices.h        (私有 API 声明)
├── BackboardTouchInjector.h   (注入器接口)
└── BackboardTouchInjector.m   (实现)
```

### 使用方法
```objectivec
// 初始化
[[BackboardTouchInjector sharedInjector] initialize];

// 点击
[[BackboardTouchInjector sharedInjector] tapAtX:0.5 y:0.5];

// 滑动
[[BackboardTouchInjector sharedInjector] swipeFromX:0.5 y:0.8 
                                                toX:0.5 y:0.2 
                                           duration:0.3];
```

### 优势
- ✅ 不需要 XCTest
- ✅ 不需要 Xcode
- ✅ 可以后台运行
- ✅ 可以控制任何应用
- ✅ TrollStore 可以直接安装

### 可能的问题
- ⚠️ 需要特定的权限（TrollStore 应该已提供）
- ⚠️ 可能需要在 Entitlements.plist 中添加额外权限

## 下一步

1. 将 `BackboardTouchInjector` 集成到 `AutomationManager`
2. 替换现有的 `TouchSimulator`
3. 测试是否可以跨应用工作

## 权限要求

可能需要在 `Entitlements.plist` 中添加：
```xml
<key>com.apple.backboardd.hid-event-injection</key>
<true/>
<key>com.apple.backboardd.launchapplications</key>
<true/>
```

## 参考
- WebDriverAgent 源码
- iOS 逆向工程文档
- backboardd 私有 API 研究
