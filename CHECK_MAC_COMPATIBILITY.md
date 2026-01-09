# 🔍 检查你的 Mac 支持什么系统

## 第一步：查看 Mac 型号和年份

### 在终端运行以下命令

```bash
# 查看完整硬件信息
system_profiler SPHardwareDataType
```

**或者分别运行：**

```bash
# 查看型号
system_profiler SPHardwareDataType | grep "Model Name"

# 查看型号标识符
system_profiler SPHardwareDataType | grep "Model Identifier"

# 查看序列号（可以查询年份）
system_profiler SPHardwareDataType | grep "Serial Number"
```

---

## 第二步：根据型号查看支持的系统

### MacBook Pro 支持表

| 型号 | 年份 | 最高支持的 macOS |
|------|------|----------------|
| MacBook Pro (16-inch, 2021) | 2021 | macOS 14 (Sonoma) |
| MacBook Pro (13/14/16-inch, 2020) | 2020 | macOS 14 (Sonoma) |
| MacBook Pro (13/15/16-inch, 2019) | 2019 | macOS 14 (Sonoma) |
| MacBook Pro (13/15-inch, 2018) | 2018 | macOS 14 (Sonoma) |
| MacBook Pro (13/15-inch, 2017) | 2017 | macOS 14 (Sonoma) |
| MacBook Pro (13/15-inch, 2016) | 2016 | macOS 14 (Sonoma) |
| MacBook Pro (Retina, 13/15-inch, 2015) | 2015 | macOS 12 (Monterey) |
| MacBook Pro (Retina, 13/15-inch, 2014) | 2014 | macOS 12 (Monterey) |
| MacBook Pro (Retina, 13/15-inch, 2013) | 2013 | macOS 11 (Big Sur) |
| MacBook Pro (13/15-inch, 2012) | 2012 | macOS 10.15 (Catalina) |
| MacBook Pro (2011 或更早) | 2011- | macOS 10.13 (High Sierra) |

### MacBook Air 支持表

| 型号 | 年份 | 最高支持的 macOS |
|------|------|----------------|
| MacBook Air (M1/M2, 2020-2022) | 2020+ | macOS 14 (Sonoma) |
| MacBook Air (Retina, 13-inch, 2018-2019) | 2018-2019 | macOS 14 (Sonoma) |
| MacBook Air (13-inch, 2017) | 2017 | macOS 12 (Monterey) |
| MacBook Air (13-inch, 2015-2016) | 2015-2016 | macOS 12 (Monterey) |
| MacBook Air (13-inch, 2013-2014) | 2013-2014 | macOS 11 (Big Sur) |
| MacBook Air (13-inch, 2012) | 2012 | macOS 10.15 (Catalina) |
| MacBook Air (2011 或更早) | 2011- | macOS 10.13 (High Sierra) |

### iMac 支持表

| 型号 | 年份 | 最高支持的 macOS |
|------|------|----------------|
| iMac (24-inch, M1, 2021) | 2021 | macOS 14 (Sonoma) |
| iMac (Retina 4K/5K, 2019-2020) | 2019-2020 | macOS 14 (Sonoma) |
| iMac (Retina 4K/5K, 2017-2018) | 2017-2018 | macOS 14 (Sonoma) |
| iMac (Retina 4K/5K, 2015-2016) | 2015-2016 | macOS 12 (Monterey) |
| iMac (21.5/27-inch, 2014) | 2014 | macOS 11 (Big Sur) |
| iMac (21.5/27-inch, 2013) | 2013 | macOS 10.15 (Catalina) |
| iMac (2012 或更早) | 2012- | macOS 10.13 (High Sierra) |

### Mac mini 支持表

| 型号 | 年份 | 最高支持的 macOS |
|------|------|----------------|
| Mac mini (M1/M2, 2020-2023) | 2020+ | macOS 14 (Sonoma) |
| Mac mini (2018) | 2018 | macOS 14 (Sonoma) |
| Mac mini (2014) | 2014 | macOS 12 (Monterey) |
| Mac mini (2012-2013) | 2012-2013 | macOS 10.15 (Catalina) |
| Mac mini (2011 或更早) | 2011- | macOS 10.13 (High Sierra) |

---

## 第三步：下载对应的 macOS

### 如果你的 Mac 支持 macOS 12 (Monterey)

**方法 1：直接链接下载**

访问：https://apps.apple.com/us/app/macos-monterey/id1576738294

**方法 2：通过系统偏好设置**

1. 点击 Apple 菜单 () > **系统偏好设置**
2. 点击 **软件更新**
3. 如果显示 macOS Monterey，点击 **立即升级**

**方法 3：手动下载安装器**

```bash
# 下载 macOS Monterey 安装器
softwareupdate --fetch-full-installer --full-installer-version 12.7.2
```

### 如果你的 Mac 只支持 macOS 11 (Big Sur)

**你已经在最高版本了！**

- 当前：macOS 11.7.10
- 最高：macOS 11.7.10

**这种情况下：**
- ✅ 使用 Xcode 13.2.1（完全够用）
- ✅ 或使用 GitHub Actions 编译（推荐）

### 如果你的 Mac 只支持 macOS 10.15 (Catalina)

**需要降级或保持现状**

- 使用 Xcode 12.4
- 或使用 GitHub Actions 编译

---

## 📊 macOS 和 Xcode 对应关系

| 你的 Mac 最高支持 | 可以安装的 Xcode | 可以编译的 iOS | 够用吗？ |
|----------------|----------------|--------------|---------|
| macOS 14 (Sonoma) | Xcode 15.4 | iOS 17.5 | ✅ 最佳 |
| macOS 13 (Ventura) | Xcode 15.2 | iOS 17.2 | ✅ 很好 |
| macOS 12 (Monterey) | Xcode 14.2 | iOS 16.2 | ✅ 推荐 |
| macOS 11 (Big Sur) | Xcode 13.2 | iOS 15.2 | ✅ 够用 |
| macOS 10.15 (Catalina) | Xcode 12.4 | iOS 14.4 | ✅ 可用 |

---

## 🎯 快速检查脚本

### 创建并运行这个脚本

```bash
#!/bin/bash

echo "=== Mac 系统信息检查 ==="
echo ""

# 当前系统版本
echo "当前系统版本："
sw_vers
echo ""

# Mac 型号
echo "Mac 型号："
system_profiler SPHardwareDataType | grep "Model Name"
system_profiler SPHardwareDataType | grep "Model Identifier"
echo ""

# 年份（从序列号推断）
echo "序列号："
system_profiler SPHardwareDataType | grep "Serial Number"
echo ""

# 判断支持的最高 macOS
MODEL_ID=$(system_profiler SPHardwareDataType | grep "Model Identifier" | awk '{print $3}')
echo "型号标识符: $MODEL_ID"
echo ""

# 简单判断
if [[ $MODEL_ID == *"2015"* ]] || [[ $MODEL_ID == *"2016"* ]] || [[ $MODEL_ID == *"2017"* ]] || [[ $MODEL_ID == *"2018"* ]] || [[ $MODEL_ID == *"2019"* ]] || [[ $MODEL_ID == *"2020"* ]] || [[ $MODEL_ID == *"2021"* ]] || [[ $MODEL_ID == *"2022"* ]]; then
    echo "✅ 你的 Mac 可能支持 macOS 12 (Monterey) 或更高"
    echo "建议：升级到 macOS 12，安装 Xcode 14"
elif [[ $MODEL_ID == *"2013"* ]] || [[ $MODEL_ID == *"2014"* ]]; then
    echo "✅ 你的 Mac 可能支持 macOS 11 (Big Sur)"
    echo "建议：保持 macOS 11，使用 Xcode 13.2.1"
else
    echo "⚠️ 你的 Mac 可能比较旧"
    echo "建议：使用 GitHub Actions 编译（免费）"
fi

echo ""
echo "=== 检查完成 ==="
```

**使用方法：**

```bash
# 1. 创建脚本
nano check_mac.sh

# 2. 粘贴上面的内容，保存（Ctrl+O, Enter, Ctrl+X）

# 3. 添加执行权限
chmod +x check_mac.sh

# 4. 运行
./check_mac.sh
```

---

## 💡 我的建议

### 运行检查脚本后

**把结果发给我，包括：**
1. 当前系统版本
2. Mac 型号
3. 型号标识符

**我会告诉你：**
1. ✅ 你的 Mac 能升级到什么版本
2. ✅ 如何下载和安装
3. ✅ 应该安装哪个版本的 Xcode
4. ✅ 详细的操作步骤

---

## 🚀 如果你的 Mac 太旧

**不用担心！我们有其他方案：**

### 方案 1：使用 GitHub Actions（推荐）
- ✅ 完全免费
- ✅ 使用最新的 Xcode 15
- ✅ 自动化编译

### 方案 2：使用云端 Mac
- ✅ 按小时付费（$1-2/小时）
- ✅ 最新环境

### 方案 3：使用当前的 Xcode 13.2.1
- ✅ 完全够用于我们的项目
- ✅ 稳定可靠

---

请运行检查脚本，然后把结果告诉我！🔍
