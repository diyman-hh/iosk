# TrollTouch 无 Xcode 使用指南

## 问题解答

### 1. "Open with JIT" 是什么？

**JIT (Just-In-Time) 编译** 是 TrollStore 的特殊功能：

- **普通模式**：代码提前编译（AOT）
- **JIT 模式**：运行时动态编译代码
- **用途**：模拟器、游戏引擎、JavaScript 引擎等

**对于 TrollTouch**：
- ✅ 使用普通安装即可
- ❌ 不需要 JIT

### 2. 没有 Xcode 如何测试？

我已经添加了**自动启动测试**功能！

## 新功能：应用内启动测试

### 工作原理

TrollTouch 现在可以：
1. 启动应用
2. 点击 "启动自动化测试" 按钮
3. 测试会自动在后台运行
4. 无需 Xcode！

### 使用步骤

#### 1. 编译和安装

```bash
cd /path/to/iosk
make clean
make package
make install
```

#### 2. 在设备上运行

1. 打开 TrollTouch 应用
2. 点击 **"🚀 启动自动化测试"** 按钮
3. 确认启动
4. 测试开始运行

#### 3. 查看日志

由于测试在后台运行，你需要查看系统日志：

**方法 A：使用 idevicesyslog（推荐）**
```bash
# 安装 libimobiledevice
# Windows: 下载预编译版本
# Mac: brew install libimobiledevice

# 实时查看日志
idevicesyslog | grep TrollTouch

# 或者只看 XCTest 相关
idevicesyslog | grep -E "TrollTouch|XCTest"
```

**方法 B：使用 Console.app（Mac）**
1. 打开 Console.app
2. 连接设备
3. 搜索 "TrollTouch"

**方法 C：使用 3uTools/iTools**
1. 打开工具箱
2. 选择 "实时日志"
3. 搜索 "TrollTouch"

### 日志示例

成功运行时，你会看到：

```
[XCTestRunner] 开始加载测试...
[XCTestRunner] 测试 Bundle 加载成功
[XCTestRunner] 找到测试类: TrollTouchUITests
[XCTestRunner] 开始运行测试: testTikTokAutomation
[TrollTouch] XCTest 自动化测试启动
[*] 开始自动化，目标: 100 个视频

--- 视频 #1 ---
[*] 观看 5 秒...
[*] 执行点赞
[*] 执行滑动: (0.52, 0.76) -> (0.48, 0.24)

--- 视频 #2 ---
...
```

## 技术实现

### XCTestRunner

新增的 `XCTestRunner` 类可以：
- 动态加载 XCTest Bundle
- 查找测试类
- 创建测试实例
- 在后台运行测试

### 关键代码

```objectivec
// 加载测试 Bundle
NSBundle *testBundle = [NSBundle bundleWithPath:testBundlePath];
[testBundle loadAndReturnError:&error];

// 获取测试类
Class testClass = NSClassFromString(@"TrollTouchUITests");

// 创建并运行测试
XCTestCase *testCase = [[testClass alloc] initWithSelector:@selector(testTikTokAutomation)];
[testCase invokeTest];
```

## 优势

### vs 方案 A（前台透明模式）
| 特性 | 前台透明 | XCTest |
|------|---------|--------|
| 后台运行 | ❌ | ✅ |
| 可以切换应用 | ❌ | ✅ |
| 可以锁屏 | ❌ | ⚠️ 部分支持 |
| API 类型 | 私有 | 官方 |

### vs WebDriverAgent
| 特性 | WDA | TrollTouch XCTest |
|------|-----|-------------------|
| 需要 Xcode | ✅ | ❌ |
| 需要 HTTP 服务器 | ✅ | ❌ |
| 独立应用 | ❌ | ✅ |
| 一键启动 | ❌ | ✅ |

## 故障排查

### 问题：点击按钮后没反应

**解决**：
1. 查看系统日志
2. 检查是否有错误信息
3. 确认测试 Bundle 是否正确安装

### 问题：找不到测试 Bundle

**错误日志**：
```
[XCTestRunner] 错误: 找不到测试 Bundle
```

**解决**：
1. 检查 `make package` 是否成功
2. 确认 `.deb` 包含 `PlugIns/TrollTouchUITests.xctest`
3. 重新安装应用

### 问题：找不到测试类

**错误日志**：
```
[XCTestRunner] 错误: 找不到测试类 TrollTouchUITests
```

**解决**：
1. 确认 `TrollTouchUITests.m` 编译成功
2. 检查类名是否正确
3. 重新编译

### 问题：TikTok 没有启动

**解决**：
1. 确认 TikTok 已安装
2. 检查 Bundle ID 是否正确：
   - 国际版：`com.zhiliaoapp.musically`
   - 国内版：`com.ss.iphone.ugc.Aweme`
3. 查看测试日志中的错误

## 配置参数

在 `TrollTouchUITests.m` 中修改：

```objectivec
int totalVideos = 100;        // 总视频数
int minWatchSec = 3;          // 最少观看秒数
int maxWatchSec = 8;          // 最多观看秒数
int likeChance = 30;          // 点赞概率 (%)
int followChance = 5;         // 关注概率 (%)
```

修改后需要重新编译：
```bash
make clean
make package
make install
```

## 下一步

1. **编译并安装**
2. **启动应用**
3. **点击启动按钮**
4. **查看日志**确认运行
5. **调整参数**优化行为

## 注意事项

1. ⚠️ 测试运行时，TrollTouch 应用可以最小化
2. ⚠️ 但不要完全关闭应用（从多任务中滑掉）
3. ⚠️ 首次运行可能需要授权 TikTok 访问
4. ⚠️ 确保设备有足够电量或连接充电器

## 技术支持

如果遇到问题：
1. 查看系统日志
2. 检查错误信息
3. 确认所有文件都正确编译和安装

所有日志都包含 `[TrollTouch]` 或 `[XCTestRunner]` 前缀。
