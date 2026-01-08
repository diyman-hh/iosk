# 🍎 Mac 编译指南：系统和 Xcode 版本要求

## 📋 第一步：检查你的 Mac

### 查看当前系统版本

打开终端（Terminal），运行：
```bash
sw_vers
```

你会看到类似这样的输出：
```
ProductName:    macOS
ProductVersion: 12.6
BuildVersion:   21G115
```

### 查看 Mac 型号

```bash
system_profiler SPHardwareDataType | grep "Model"
```

---

## 🎯 推荐配置

### 目标：编译 iOS 14.0+ 应用

**最低要求：**
- **macOS**: 11.0 (Big Sur) 或更高
- **Xcode**: 12.0 或更高

**推荐配置：**
- **macOS**: 12.0 (Monterey) 或 13.0 (Ventura)
- **Xcode**: 14.0 或 15.0

---

## 📊 macOS 和 Xcode 兼容性表

| macOS 版本 | 最高支持的 Xcode | 可编译的 iOS 版本 | 推荐 |
|-----------|----------------|-----------------|------|
| macOS 10.15 (Catalina) | Xcode 12.4 | iOS 14.4 | ⚠️ 可用 |
| macOS 11 (Big Sur) | Xcode 13.2.1 | iOS 15.2 | ✅ 推荐 |
| macOS 12 (Monterey) | Xcode 14.2 | iOS 16.2 | ✅ 推荐 |
| macOS 13 (Ventura) | Xcode 15.2 | iOS 17.2 | ✅ 最佳 |
| macOS 14 (Sonoma) | Xcode 15.3+ | iOS 17.4+ | ✅ 最新 |

---

## 🔍 根据你的 Mac 型号选择

### 如果你的 Mac 是 2015 年或更新
**推荐：** 升级到 macOS 12 (Monterey) + Xcode 14

**步骤：**
1. 升级到 macOS 12 Monterey
2. 安装 Xcode 14.2

### 如果你的 Mac 是 2012-2014 年
**推荐：** 升级到 macOS 11 (Big Sur) + Xcode 13

**步骤：**
1. 升级到 macOS 11 Big Sur
2. 安装 Xcode 13.2.1

### 如果你的 Mac 是 2012 年之前
**推荐：** 保持 macOS 10.15 (Catalina) + Xcode 12

**步骤：**
1. 升级到 macOS 10.15 Catalina（如果可能）
2. 安装 Xcode 12.4

---

## 📥 安装步骤

### 方法 1：从 App Store 安装（推荐）

#### 1. 升级 macOS

```bash
# 检查可用更新
softwareupdate --list

# 升级到最新版本
softwareupdate --install --all
```

或者：
- 打开 **系统偏好设置** > **软件更新**
- 点击 **立即升级**

#### 2. 安装 Xcode

**从 App Store：**
1. 打开 App Store
2. 搜索 "Xcode"
3. 点击 "获取" 或 "下载"
4. 等待下载完成（约 10-15 GB）

**安装完成后：**
```bash
# 接受许可协议
sudo xcodebuild -license accept

# 安装命令行工具
sudo xcode-select --install

# 验证安装
xcodebuild -version
```

---

### 方法 2：手动下载安装

#### 1. 下载 Xcode

访问：https://developer.apple.com/download/all/

**不需要付费开发者账号！** 使用免费的 Apple ID 即可。

**选择版本：**
- 根据你的 macOS 版本选择兼容的 Xcode
- 下载 `.xip` 文件

#### 2. 安装 Xcode

```bash
# 解压 .xip 文件（双击或使用命令）
xip -x Xcode_14.2.xip

# 移动到 Applications 文件夹
sudo mv Xcode.app /Applications/

# 选择 Xcode
sudo xcode-select -s /Applications/Xcode.app

# 接受许可
sudo xcodebuild -license accept

# 安装额外组件
sudo xcodebuild -runFirstLaunch
```

---

## 🚀 快速开始（最简配置）

### 如果你不想升级系统

**最低要求：**
- macOS 10.15 (Catalina)
- Xcode 12.4

**步骤：**

1. **检查当前版本**
   ```bash
   sw_vers
   ```

2. **如果是 macOS 10.15 或更高**
   - 直接从 App Store 安装 Xcode
   - 或下载 Xcode 12.4

3. **如果低于 macOS 10.15**
   - 升级到 macOS 10.15
   - 然后安装 Xcode 12.4

---

## 📝 我的推荐

### 场景 1：Mac 比较新（2015+）
```
macOS 12 (Monterey) + Xcode 14.2
```

### 场景 2：Mac 比较旧（2012-2014）
```
macOS 11 (Big Sur) + Xcode 13.2
```

### 场景 3：Mac 很旧（2012 之前）
```
macOS 10.15 (Catalina) + Xcode 12.4
```

---

## ⚡ 编译我们的项目

### 安装完 Xcode 后

1. **克隆项目**
   ```bash
   cd ~/Desktop
   git clone https://github.com/[your-username]/iosk.git
   cd iosk
   ```

2. **打开项目**
   ```bash
   # 如果有 .xcodeproj 文件
   open TrollTouch.xcodeproj
   
   # 或者创建新的 Xcode 项目
   ```

3. **编译**
   - 在 Xcode 中选择目标设备
   - Product > Build (⌘B)
   - Product > Archive

---

## 🔧 故障排查

### 问题：无法升级到更高版本的 macOS

**原因：** Mac 硬件太旧

**解决：** 使用当前支持的最高版本

### 问题：Xcode 下载太慢

**解决：**
1. 使用迅雷等下载工具
2. 或使用 `aria2c` 命令行工具
3. 或从第三方镜像下载

### 问题：磁盘空间不足

**Xcode 需要：**
- 下载：约 10-15 GB
- 安装后：约 20-30 GB

**解决：** 清理磁盘空间或使用外置硬盘

---

## 📞 下一步

安装完成后，请告诉我：
1. 你的 macOS 版本
2. 你的 Xcode 版本

我会指导你如何编译项目！
