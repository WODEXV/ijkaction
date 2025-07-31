#!/bin/bash

# OpenHarmony SDK 结构设置脚本
# 用于在 GitHub Actions 中正确设置 SDK 目录结构

set -e  # 遇到错误立即退出

SDK_BASE_DIR="/opt/ohos-sdk-4.1"
SDK_LINUX_DIR="$SDK_BASE_DIR/ohos-sdk/linux/11"
SDK_WINDOWS_DIR="$SDK_BASE_DIR/ohos-sdk/windows/11"

echo "=== OpenHarmony SDK 结构设置 ==="

# 注意：此脚本假设 SDK 已经解压到 /opt/ohos-sdk-4.1/ 目录
# 正确的操作顺序：
# 1. tar -xzf ohos-sdk-full.tar.gz -C /opt/ohos-sdk-4.1/
# 2. 在 /opt/ohos-sdk-4.1/ohos-sdk/linux/ 中找到 zip 文件
# 3. 创建 11 文件夹
# 4. 将 zip 文件解压到 11 文件夹下

# 步骤3: 创建 11 目录结构
echo "创建 SDK 目录结构..."
mkdir -p "$SDK_LINUX_DIR"
mkdir -p "$SDK_WINDOWS_DIR"

# 查找所有 zip 文件，首先在 ohos-sdk/linux 目录下查找
echo "查找 SDK zip 文件..."

# 先检查 ohos-sdk/linux 目录
if [ -d "ohos-sdk/linux" ]; then
    echo "在 ohos-sdk/linux 目录中查找 zip 文件..."
    ZIP_FILES=$(find ohos-sdk/linux -name "*.zip" -type f)
    ZIP_SEARCH_DIR="ohos-sdk/linux"
elif [ -d "ohos-sdk" ]; then
    echo "在 ohos-sdk 目录中查找 zip 文件..."
    ZIP_FILES=$(find ohos-sdk -name "*.zip" -type f)
    ZIP_SEARCH_DIR="ohos-sdk"
else
    echo "在当前目录中查找 zip 文件..."
    ZIP_FILES=$(find . -maxdepth 3 -name "*.zip" -type f)
    ZIP_SEARCH_DIR="."
fi

if [ -z "$ZIP_FILES" ]; then
    echo "❌ 未找到任何 zip 文件"
    echo "当前目录结构："
    ls -la
    if [ -d "ohos-sdk" ]; then
        echo "ohos-sdk 目录内容："
        ls -la ohos-sdk/
        if [ -d "ohos-sdk/linux" ]; then
            echo "ohos-sdk/linux 目录内容："
            ls -la ohos-sdk/linux/
        fi
    fi
    exit 1
fi

echo "在 $ZIP_SEARCH_DIR 中找到以下 zip 文件："
echo "$ZIP_FILES"

# 解压 Linux 相关的 zip 文件
echo ""
echo "=== 解压 Linux SDK 组件到 $SDK_LINUX_DIR ==="

for zip_file in $ZIP_FILES; do
    filename=$(basename "$zip_file")
    echo "处理: $filename"
    
    # 根据文件名判断是否为 Linux 组件
    if [[ "$filename" == *"linux"* ]] || \
       [[ "$filename" == *"ets-"* ]] || \
       [[ "$filename" == *"js-"* ]] || \
       [[ "$filename" == *"native-"* ]] || \
       [[ "$filename" == *"previewer-"* ]] || \
       [[ "$filename" == *"toolchains-"* ]]; then
        
        echo "  → 解压到 Linux 目录: $filename"
        unzip -q "$zip_file" -d "$SDK_LINUX_DIR/"
        
        # 检查解压结果
        if [ $? -eq 0 ]; then
            echo "  ✅ 解压成功"
        else
            echo "  ❌ 解压失败"
        fi
    else
        echo "  → 跳过 (非 Linux 组件): $filename"
    fi
done

# 检查解压结果
echo ""
echo "=== SDK 目录结构检查 ==="
echo "Linux SDK 目录内容:"
ls -la "$SDK_LINUX_DIR/"

# 查找关键组件
echo ""
echo "=== 关键组件检查 ==="

# 查找 native 目录
NATIVE_DIR=$(find "$SDK_LINUX_DIR" -name "native" -type d | head -1)
if [ -n "$NATIVE_DIR" ]; then
    echo "✅ 找到 native 目录: $NATIVE_DIR"
    ls -la "$NATIVE_DIR/"
    
    # 查找 clang
    CLANG_PATH=$(find "$NATIVE_DIR" -name "clang" -type f | head -1)
    if [ -n "$CLANG_PATH" ]; then
        echo "✅ 找到 clang: $CLANG_PATH"
    else
        echo "⚠️  未找到 clang，查找所有可执行文件："
        find "$NATIVE_DIR" -type f -executable | head -5
    fi
else
    echo "⚠️  未找到 native 目录，列出所有目录："
    find "$SDK_LINUX_DIR" -type d | head -10
fi

# 查找其他重要组件
echo ""
echo "=== 其他组件检查 ==="
for component in "ets" "js" "previewer" "toolchains"; do
    COMP_DIR=$(find "$SDK_LINUX_DIR" -name "*$component*" -type d | head -1)
    if [ -n "$COMP_DIR" ]; then
        echo "✅ 找到 $component: $COMP_DIR"
    else
        echo "⚠️  未找到 $component 组件"
    fi
done

# 设置执行权限
echo ""
echo "=== 设置执行权限 ==="
find "$SDK_LINUX_DIR" -type f -exec chmod +x {} \; 2>/dev/null || true
echo "✅ 权限设置完成"

# 最终验证
echo ""
echo "=== 最终验证 ==="
export OHOS_SDK="$SDK_LINUX_DIR"
echo "OHOS_SDK=$OHOS_SDK"

# 尝试运行 clang
CLANG_PATH=$(find "$SDK_LINUX_DIR" -name "clang" -type f | head -1)
if [ -n "$CLANG_PATH" ]; then
    echo "测试 clang:"
    file "$CLANG_PATH"
    "$CLANG_PATH" --version 2>/dev/null || echo "clang 无法运行，但文件存在"
else
    echo "⚠️  最终检查：未找到 clang"
fi

echo ""
echo "=== SDK 设置完成 ==="
