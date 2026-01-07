# 编译和测试指南

## 编译错误修复

当前编译错误：
```
"_OBJC_CLASS_$_BackboardTouchInjector", referenced from:
    in AutomationManager.m.656ae345.o
```

这是链接器错误，表示 `BackboardTouchInjector.m` 没有被正确编译。

## 解决方案

### 1. 清理并重新编译

在 **WSL** 或 **Git Bash** 中运行：

```bash
cd /d/project/iosk

# 完全清理
rm -rf .theos packages
make clean

# 重新编译
make package

# 安装
make install
```

### 2. 如果在 PowerShell 中

PowerShell 可能找不到 `make` 命令。请：

**选项 A：使用 WSL**
```powershell
wsl
cd /mnt/d/project/iosk
make clean
make package
make install
```

**选项 B：使用 Git Bash**
- 打开 Git Bash
- `cd /d/project/iosk`
- `make clean && make package && make install`

### 3. 验证文件存在

确认以下文件都存在：
```
TrollTouch/BackboardTouchInjector.h
TrollTouch/BackboardTouchInjector.m
TrollTouch/BackboardServices.h
```

## 编译后测试

### 1. 查看日志

在设备上运行后，查看日志：

**方法 A：查看文件**
```
/var/mobile/Documents/app.log
```

**方法 B：实时日志（PowerShell）**
```powershell
idevicesyslog | Select-String "Backboard"
```

**方法 C：实时日志（WSL/Bash）**
```bash
idevicesyslog | grep Backboard
```

### 2. 预期日志输出

启动时应该看到：
```
[系统] 初始化 BackboardServices 触摸注入...
[Backboard] Initializing system-level touch injection...
[Backboard] Event port: 2803
[Backboard] ✅ Initialized successfully!
[Backboard] BKSendHIDEvent: 0x1a2b3c4d5
[系统] ✅ BackboardServices 初始化成功 - 可以跨应用控制！
```

点击时应该看到：
```
[*] 执行点赞 (坐标: 0.50, 0.50)
[Backboard] Tap at (0.50, 0.50)
[Backboard] ✅ Sent event: phase=1 at (375, 667)
[Backboard] ✅ Sent event: phase=3 at (375, 667)
```

### 3. 如果初始化失败

如果看到：
```
[Backboard] ERROR: Failed to load BackboardServices
```

或：
```
[Backboard] ERROR: BKSendHIDEvent not found
```

可能需要添加额外的权限到 `Entitlements.plist`：

```xml
<key>com.apple.backboardd.hid-event-injection</key>
<true/>
<key>com.apple.backboardd.launchapplications</key>
<true/>
```

## 故障排查

### 问题：编译时找不到 BackboardTouchInjector

**解决**：
1. 确认 `Makefile` 中有 `TrollTouch/BackboardTouchInjector.m`
2. 运行 `make clean`
3. 删除 `.theos` 目录
4. 重新编译

### 问题：触摸仍然无效

**解决**：
1. 检查日志确认 BackboardServices 初始化成功
2. 确认 TikTok 已启动
3. 尝试手动点击测试按钮
4. 查看是否有权限错误

### 问题：应用崩溃

**解决**：
1. 查看崩溃日志
2. 可能是 IOHIDEvent 创建失败
3. 检查 iOS 版本兼容性

## 下一步

如果 BackboardServices 工作：
- ✅ 这是最终解决方案
- ✅ 可以真正实现跨应用控制

如果 BackboardServices 不工作：
- 尝试添加更多权限
- 研究 iOS 15.8.5 的具体限制
- 考虑其他备选方案
