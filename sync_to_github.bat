@echo off
chcp 65001 >nul
echo.
echo ==========================================
echo      Git 同步到 GitHub
echo ==========================================
echo.

:: 检查是否在git仓库中
git rev-parse --git-dir >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ 错误：当前目录不是 Git 仓库！
    pause
    exit /b 1
)

:: 显示当前分支
echo 📌 当前分支:
git branch --show-current
echo.

:: 显示修改的文件
echo 📝 修改的文件:
git status --short
echo.

:: 检查是否有修改
git diff-index --quiet HEAD --
if %errorlevel% equ 0 (
    echo ⚠️  没有检测到修改，无需提交。
    echo.
    pause
    exit /b 0
)

:: 添加所有修改
echo 📦 正在暂存所有修改...
git add .
echo ✅ 文件已暂存
echo.

:: 处理提交信息
:: 如果命令行传入了参数，使用参数作为提交信息
if not "%~1"=="" (
    set "commit_msg=%~1"
    echo 💬 使用提交信息: %commit_msg%
) else (
    :: 询问提交信息
    set /p "commit_msg=💬 请输入提交说明 (直接回车默认'Update'): "
    if "!commit_msg!"=="" set "commit_msg=Update"
)

:: 提交
echo.
echo 📌 正在提交...
git commit -m "%commit_msg%"

if %errorlevel% neq 0 (
    echo ❌ 提交失败！
    pause
    exit /b 1
)

echo ✅ 提交成功
echo.

:: 显示最近一次提交
echo 📋 最近提交:
git log -1 --oneline
echo.

:: 推送
echo 🚀 正在推送到 GitHub...
git push origin main

if %errorlevel% equ 0 (
    echo.
    echo ==========================================
    echo      ✅ 同步成功！
    echo.
    echo      可以在 GitHub Actions 查看构建:
    echo      https://github.com/diyman-hh/iosk/actions
    echo ==========================================
) else (
    echo.
    echo ==========================================
    echo      ❌ 推送失败
    echo.
    echo      可能的原因:
    echo      1. 网络连接问题
    echo      2. 需要先 git pull
    echo      3. 没有推送权限
    echo ==========================================
)

echo.
pause
