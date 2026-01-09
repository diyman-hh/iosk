# 🚀 使用 OpenCore Legacy Patcher 升级 macOS

## ⚠️ 重要警告

**在开始之前，请注意：**

1. ⚠️ **备份所有数据** - 使用 Time Machine 或其他方式
2. ⚠️ **可能不稳定** - 某些功能可能无法正常工作
3. ⚠️ **性能可能下降** - 旧硬件运行新系统可能较慢
4. ⚠️ **风险自负** - 这不是官方支持的方法

**建议先阅读完整指南再操作！**

---

## 📥 下载 OpenCore Legacy Patcher

### 官方下载地址

**GitHub 官方仓库：**
```
https://github.com/dortania/OpenCore-Legacy-Patcher
```

**直接下载最新版本：**
```
https://github.com/dortania/OpenCore-Legacy-Patcher/releases
```

### 下载步骤

1. **访问 Releases 页面**
   - 打开：https://github.com/dortania/OpenCore-Legacy-Patcher/releases
   - 找到最新版本（例如：0.6.9）

2. **下载应用程序**
   - 下载 `OpenCore-Patcher-GUI.app.zip`
   - 或下载 `OpenCore-Patcher.pkg`

3. **解压并打开**
   ```bash
   # 解压
   unzip OpenCore-Patcher-GUI.app.zip
   
   # 移动到 Applications
   mv "OpenCore-Patcher.app" /Applications/
   
   # 打开应用
   open /Applications/OpenCore-Patcher.app
   ```

---

## 🎯 你的 Mac 可以升级到什么版本

### MacBook Pro (Retina, 13-inch, Late 2013)

**官方支持：** macOS 11 (Big Sur)
**使用 OCLP 可以升级到：** macOS 14 (Sonoma)

**推荐升级到：**
- ✅ macOS 12 (Monterey) - 最稳定
- ✅ macOS 13 (Ventura) - 较稳定
- ⚠️ macOS 14 (Sonoma) - 可能不稳定

---

## 📋 完整升级步骤

### 准备工作

#### 1. 备份数据（必须！）

```bash
# 使用 Time Machine 备份
# 或手动备份重要文件到外置硬盘
```

#### 2. 准备 USB 驱动器

- 至少 16 GB
- 将被完全格式化

#### 3. 下载 OCLP

从上面的链接下载最新版本

---

### 步骤 1：创建 macOS 安装器

#### 1.1 打开 OpenCore Patcher

```bash
open /Applications/OpenCore-Patcher.app
```

#### 1.2 创建安装器

1. 点击 **"Create macOS Installer"**
2. 选择要安装的 macOS 版本：
   - **推荐：macOS 12 (Monterey)**
   - 或 macOS 13 (Ventura)
3. 选择你的 USB 驱动器
4. 点击 **"Download and Create Installer"**
5. 等待下载和创建（需要 1-2 小时）

---

### 步骤 2：构建和安装 OpenCore

#### 2.1 构建 OpenCore

1. 在 OCLP 主界面，点击 **"Build and Install OpenCore"**
2. 选择你的 Mac 型号（应该自动检测）
3. 点击 **"Build OpenCore"**
4. 等待构建完成

#### 2.2 安装 OpenCore 到 USB

1. 点击 **"Install OpenCore"**
2. 选择 **"Install to disk"**
3. 选择你的 USB 驱动器
4. 点击 **"Install"**

---

### 步骤 3：从 USB 启动并安装 macOS

#### 3.1 重启 Mac

1. 关闭 Mac
2. 插入 USB 驱动器
3. 按住 **Option (⌥)** 键开机
4. 选择 **"EFI Boot"** 或 **"OpenCore"**

#### 3.2 安装 macOS

1. 选择 **"Install macOS Monterey"**（或你选择的版本）
2. 选择 **"磁盘工具"** > 抹掉主硬盘（可选，全新安装）
3. 退出磁盘工具
4. 选择 **"安装 macOS"**
5. 按照提示操作
6. 等待安装完成（需要 30-60 分钟）

---

### 步骤 4：安装后配置

#### 4.1 安装 OpenCore 到主硬盘

安装完成后：

1. 打开 OpenCore Patcher
2. 点击 **"Post-Install Root Patch"**
3. 点击 **"Start Root Patching"**
4. 等待完成
5. 重启

#### 4.2 安装 OpenCore 引导

1. 再次打开 OCLP
2. 点击 **"Build and Install OpenCore"**
3. 选择 **"Install to disk"**
4. 选择主硬盘
5. 安装完成后重启

---

## 🔧 安装后可能需要的修复

### 修复图形加速

如果图形性能差：

1. 打开 OpenCore Patcher
2. 点击 **"Post-Install Root Patch"**
3. 选择 **"Graphics Acceleration"**
4. 点击 **"Patch"**
5. 重启

### 修复 Wi-Fi

如果 Wi-Fi 不工作：

1. 打开 OCLP
2. 点击 **"Post-Install Root Patch"**
3. 选择 **"Networking"**
4. 点击 **"Patch"**
5. 重启

---

## 📊 升级后可以安装的 Xcode

| 升级到的 macOS | 可以安装的 Xcode | 可以编译的 iOS |
|--------------|----------------|--------------|
| macOS 12 (Monterey) | Xcode 14.2 | iOS 16.2 |
| macOS 13 (Ventura) | Xcode 15.2 | iOS 17.2 |
| macOS 14 (Sonoma) | Xcode 15.4 | iOS 17.5 |

---

## ⚠️ 已知问题和限制

### MacBook Pro (Late 2013) 常见问题

1. **图形性能**
   - 可能比原生系统慢
   - 需要安装图形加速补丁

2. **电池续航**
   - 可能减少 10-20%

3. **某些功能可能不工作**
   - AirDrop 可能不稳定
   - Handoff 可能有问题
   - Sidecar 不支持

4. **系统更新**
   - 每次 macOS 更新后需要重新运行 Root Patch

---

## 🎯 推荐配置

### 对于你的 MacBook Pro (Late 2013)

**最佳选择：升级到 macOS 12 (Monterey)**

**原因：**
- ✅ 最稳定
- ✅ 性能损失最小
- ✅ 可以安装 Xcode 14
- ✅ 大部分功能正常

**不推荐：** macOS 14 (Sonoma)
- ⚠️ 可能很慢
- ⚠️ 更多兼容性问题

---

## 📝 详细教程视频

**推荐观看：**

1. **官方文档：**
   - https://dortania.github.io/OpenCore-Legacy-Patcher/

2. **YouTube 教程：**
   - 搜索：`OpenCore Legacy Patcher MacBook Pro 2013`
   - 推荐频道：Mr. Macintosh, Tech Craft

---

## 🚀 快速开始脚本

### 自动下载和准备

```bash
#!/bin/bash

echo "OpenCore Legacy Patcher 安装准备"
echo ""

# 检查系统
echo "当前系统："
sw_vers
echo ""

# 下载 OCLP
echo "正在下载 OpenCore Legacy Patcher..."
cd ~/Downloads

# 获取最新版本
LATEST_URL=$(curl -s https://api.github.com/repos/dortania/OpenCore-Legacy-Patcher/releases/latest | grep "browser_download_url.*GUI.app.zip" | cut -d '"' -f 4)

echo "下载地址: $LATEST_URL"
curl -L -o OpenCore-Patcher.zip "$LATEST_URL"

# 解压
echo "正在解压..."
unzip -q OpenCore-Patcher.zip

# 移动到 Applications
echo "正在安装..."
mv "OpenCore-Patcher.app" /Applications/

echo ""
echo "✅ 安装完成！"
echo ""
echo "下一步："
echo "1. 打开 /Applications/OpenCore-Patcher.app"
echo "2. 准备一个 16GB+ 的 USB 驱动器"
echo "3. 按照上面的步骤操作"
echo ""
echo "⚠️ 记得先备份数据！"
```

**使用方法：**
```bash
# 保存脚本
nano install_oclp.sh

# 粘贴上面的内容，保存

# 添加执行权限
chmod +x install_oclp.sh

# 运行
./install_oclp.sh
```

---

## 💡 我的建议

### 在开始之前

**请考虑：**

1. **你真的需要升级吗？**
   - Xcode 13.2.1 完全够用于我们的项目
   - GitHub Actions 可以使用最新 Xcode

2. **风险评估**
   - 升级可能导致系统不稳定
   - 某些功能可能无法使用
   - 性能可能下降

3. **替代方案**
   - 使用 GitHub Actions（免费）
   - 租用云端 Mac（按需付费）

### 如果决定升级

**推荐步骤：**
1. ✅ 完整备份数据
2. ✅ 升级到 macOS 12 (Monterey)，不要直接升级到 14
3. ✅ 测试稳定性
4. ✅ 安装 Xcode 14
5. ✅ 如果稳定，可以考虑升级到 macOS 13

---

## 📞 需要帮助？

**如果你决定使用 OCLP：**

1. 先下载并打开 OCLP
2. 告诉我你看到了什么
3. 我会指导你下一步

**如果你想重新考虑：**

1. 我可以帮你设置 GitHub Actions
2. 或指导你使用 Xcode 13.2.1

---

**下载链接（再次确认）：**
```
https://github.com/dortania/OpenCore-Legacy-Patcher/releases
```

**你准备好开始了吗？** 🚀
