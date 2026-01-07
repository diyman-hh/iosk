# TrollTouch - PiP 模式使用说明

## 当前实现状态

✅ **已完成**：
- 画中画（PiP）小窗口显示
- 窗口尺寸：80x120 像素
- 位置：屏幕右下角
- 显示运行状态和操作计数

⚠️ **待实现**：
- 辅助功能 API 触摸注入（方案 B）
- 窗口拖拽功能
- 操作计数器更新

## 当前功能

### PiP 窗口特性

1. **小巧不遮挡**：80x120 像素，位于右下角
2. **状态显示**：
   - 🤖 图标
   - "运行中" 文字
   - 操作计数（目前固定显示 "0 操作"）
3. **半透明背景**：深色背景 + 绿色边框
4. **始终在最前**：windowLevel = UIWindowLevelAlert + 1

### 触摸注入

目前仍使用 `IOHIDEventSystemClient` API，但由于 iOS 限制，**触摸事件无法生效**。

## 下一步：实现辅助功能 API

### 需要做的事情：

1. **添加辅助功能权限检查**
2. **实现基于 UIAccessibility 的触摸注入**
3. **引导用户授予权限**

### 用户授权流程（计划）：

1. 启动 TrollTouch
2. 应用检测到没有辅助功能权限
3. 显示引导界面
4. 用户前往：**设置 > 辅助功能 > 触控 > 辅助触控**
5. 找到并启用 TrollTouch
6. 返回应用，触摸注入开始工作

## 测试当前版本

虽然触摸注入还不工作，但你可以测试 PiP 窗口：

1. Build 并安装
2. 启动自动化
3. 观察右下角是否出现小窗口
4. 窗口应该显示：
   - 🤖 图标
   - "运行中" 文字
   - "0 操作" 计数

## 已知问题

1. ❌ **触摸事件不生效**：仍然使用 IOHIDEventSystemClient，iOS 会阻止
2. ⚠️ **窗口可能被隐藏**：切换到其他应用时，PiP 窗口可能不可见
3. ⚠️ **无法拖拽**：窗口位置固定

## 技术细节

### PiP 窗口创建

```objectivec
CGFloat pipWidth = 80;
CGFloat pipHeight = 120;
CGRect pipFrame = CGRectMake(screenBounds.size.width - pipWidth - 10,
                             screenBounds.size.height - pipHeight - 60,
                             pipWidth, pipHeight);

_overlayWindow = [[UIWindow alloc] initWithFrame:pipFrame];
_overlayWindow.windowLevel = UIWindowLevelAlert + 1;
_overlayWindow.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.85];
```

### 为什么 PiP 窗口也可能被隐藏？

即使是小窗口，iOS 仍然会在切换应用时隐藏它。这是因为：
- iOS 的窗口管理机制基于应用级别，而不是窗口级别
- 当应用进入后台，所有窗口都会被隐藏
- 即使设置最高 windowLevel 也无法绕过

### 真正的解决方案

只有以下方案可行：
1. **辅助功能 API**：官方支持，需要用户授权
2. **越狱 + backboardd**：直接与系统守护进程通信
3. **完全前台模式**：应用保持前台，使用透明界面

我们正在实现方案 1（辅助功能 API）。
