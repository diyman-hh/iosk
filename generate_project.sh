#!/bin/bash

# generate_project.sh
# 自动生成 TrollTouch.xcodeproj

echo "🛠️  正在检查 XcodeGen..."

if ! command -v xcodegen &> /dev/null; then
    echo "⚠️  未找到 XcodeGen，正在尝试通过 Homebrew 安装..."
    if ! command -v brew &> /dev/null; then
        echo "❌ 未找到 Homebrew。请先安装 Homebrew: https://brew.sh/"
        echo "或者手动下载 XcodeGen: https://github.com/yonaskolb/XcodeGen"
        exit 1
    fi
    brew install xcodegen
else
    echo "✅ XcodeGen 已安装"
fi

echo "🚀 正在生成 Xcode 项目..."
xcodegen generate

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ 成功! TrollTouch.xcodeproj 已生成。"
    echo "你可以直接双击打开 TrollTouch.xcodeproj"
    open TrollTouch.xcodeproj
else
    echo "❌ 生成失败，请检查上面的错误信息。"
fi
