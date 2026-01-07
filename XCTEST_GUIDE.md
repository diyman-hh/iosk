# TrollTouch XCTest 版本使用指南

## 重要变更

TrollTouch 现在基于 **XCTest 框架**重写，这使得它可以：
- ✅ **真正的后台运行**
- ✅ **跨应用控制** TikTok
- ✅ 使用 **官方 API**（不是私有 API）
- ✅ **稳定可靠**

## 架构说明

### 新架构
```
TrollTouch.app (宿主应用)
└── PlugIns/
    └── TrollTouchUITests.xctest (测试 Bundle)
        └── TrollTouchUITests.m (自动化逻辑)
```

### 工作原理
- **宿主应用**：TrollTouch.app 只是一个简单的界面，显示使用说明
- **测试 Bundle**：真正的自动化逻辑在 XCTest Bundle 中
- **运行方式**：通过 Xcode 或 xcodebuild 运行测试

## 编译与安装

### 1. 编译项目

```bash
cd /path/to/iosk
make clean
make package
```

这会生成：
- `TrollTouch.app` - 宿主应用
- `TrollTouch.app/PlugIns/TrollTouchUITests.xctest` - 测试 Bundle

### 2. 安装到设备

```bash
# 使用 Theos
make install

# 或手动安装
# 将 packages/*.deb 通过 TrollStore 安装
```

## 运行自动化

### 方法 1：使用 Xcode（推荐）

1. **创建 Xcode 项目**（如果还没有）：
   ```bash
   # 在项目目录创建 Xcode 项目
   # 添加 TrollTouch.app 作为 target
   # 添加 TrollTouchUITests.xctest 作为 UI Test target
   ```

2. **运行测试**：
   - 打开 Xcode
   - 选择设备
   - Product > Test (Cmd+U)
   - 或者只运行特定测试

### 方法 2：使用命令行

```bash
# 获取设备 UDID
idevice_id -l

# 运行完整自动化测试
xcodebuild test \
  -project TrollTouch.xcodeproj \
  -scheme TrollTouch \
  -destination 'platform=iOS,id=YOUR_DEVICE_UDID' \
  -only-testing:TrollTouchUITests/TrollTouchUITests/testTikTokAutomation

# 运行单次点赞测试
xcodebuild test \
  -project TrollTouch.xcodeproj \
  -scheme TrollTouch \
  -destination 'platform=iOS,id=YOUR_DEVICE_UDID' \
  -only-testing:TrollTouchUITests/TrollTouchUITests/testSingleLike
```

### 方法 3：使用 xcrun（简化版）

```bash
# 列出可用测试
xcrun xctrace list devices

# 运行测试
xcrun xcodebuild test \
  -scheme TrollTouch \
  -destination 'platform=iOS,name=iPhone'
```

## 可用测试

### 1. `testTikTokAutomation`
**完整的自动化测试**
- 启动 TikTok
- 循环处理 100 个视频
- 随机点赞（30% 概率）
- 随机关注（5% 概率）
- 自动滑动到下一个视频

### 2. `testSingleLike`
**单次点赞测试**
- 启动 TikTok
- 执行一次点赞
- 用于测试点赞功能

### 3. `testSingleSwipe`
**单次滑动测试**
- 启动 TikTok
- 执行一次滑动
- 用于测试滑动功能

## 配置参数

在 `TrollTouchUITests.m` 的 `testTikTokAutomation` 方法中：

```objectivec
int totalVideos = 100;        // 总共处理多少个视频
int minWatchSec = 3;          // 最少观看秒数
int maxWatchSec = 8;          // 最多观看秒数
int likeChance = 30;          // 点赞概率 (%)
int followChance = 5;         // 关注概率 (%)
```

## 优势对比

| 特性 | 旧版 (IOHIDEvent) | 新版 (XCTest) |
|------|------------------|---------------|
| 后台运行 | ❌ 不支持 | ✅ 支持 |
| 跨应用控制 | ❌ 需要前台 | ✅ 完全支持 |
| API 类型 | 私有 API | 官方 API |
| 稳定性 | ⚠️ 不稳定 | ✅ 稳定 |
| iOS 兼容性 | ⚠️ 受限 | ✅ 良好 |
| 运行方式 | 独立应用 | 测试 Bundle |

## 注意事项

### 1. 需要开发者证书
XCTest 需要有效的开发者证书签名。

### 2. 运行方式不同
不是通过点击应用图标启动，而是通过 Xcode 或 xcodebuild 运行测试。

### 3. 日志查看
测试日志会输出到：
- Xcode 的测试日志
- 或 xcodebuild 的输出

### 4. 停止测试
- Xcode: 点击停止按钮
- 命令行: Ctrl+C

## 故障排查

### 问题：测试无法启动
**解决**：
1. 确认设备已连接并信任
2. 确认开发者证书有效
3. 检查 Bundle ID 是否正确

### 问题：找不到 TikTok
**解决**：
1. 确认 TikTok 已安装
2. 检查 Bundle ID：
   - 国际版：`com.zhiliaoapp.musically`
   - 国内版：`com.ss.iphone.ugc.Aweme`

### 问题：触摸无效
**解决**：
1. 检查坐标是否正确
2. 调整点击/滑动的延迟时间
3. 查看测试日志中的错误信息

## 下一步

1. **编译并安装**应用
2. **创建 Xcode 项目**（如果需要）
3. **运行测试**并观察效果
4. **调整参数**以优化自动化行为

## 技术支持

如果遇到问题，请检查：
1. 设备日志
2. Xcode 测试日志
3. xcodebuild 输出

所有日志都会包含 `[TrollTouch]` 前缀，方便过滤。
