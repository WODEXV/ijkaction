#!/bin/bash

# FFmpeg VP8 支持配置修改脚本
# 用于在 tpc_c_cplusplus 下载后修改 FFmpeg 配置以支持 VP8

set -e

echo "=== FFmpeg VP8 支持配置修改脚本 ==="

FFMPEG_HPKBUILD="tpc_c_cplusplus/thirdparty/FFmpeg-ff4.0/HPKBUILD"

# 等待 FFmpeg 配置文件存在
echo "等待 FFmpeg 配置文件..."
WAIT_COUNT=0
while [ ! -f "$FFMPEG_HPKBUILD" ] && [ $WAIT_COUNT -lt 60 ]; do
    echo "等待 $FFMPEG_HPKBUILD 文件... ($WAIT_COUNT/60)"
    sleep 5
    WAIT_COUNT=$((WAIT_COUNT + 1))
done

if [ ! -f "$FFMPEG_HPKBUILD" ]; then
    echo "❌ 错误：FFmpeg 配置文件未找到: $FFMPEG_HPKBUILD"
    exit 1
fi

echo "✅ 找到 FFmpeg 配置文件: $FFMPEG_HPKBUILD"

# 备份原始文件
cp "$FFMPEG_HPKBUILD" "$FFMPEG_HPKBUILD.backup"
echo "✅ 已备份原始配置文件"

# 显示修改前的配置
echo "=== 修改前的配置 ==="
echo "依赖关系:"
grep "depends=" "$FFMPEG_HPKBUILD" || echo "未找到 depends 行"
echo "编译选项:"
grep "enable-libopenh264" "$FFMPEG_HPKBUILD" || echo "未找到 libopenh264 配置"

# 1. 添加 libvpx 依赖
echo "=== 修改 1: 添加 libvpx 依赖 ==="
if grep -q 'depends=("openssl_1_1_1w" "openh264")' "$FFMPEG_HPKBUILD"; then
    sed -i 's|depends=("openssl_1_1_1w" "openh264")|depends=("openssl_1_1_1w" "openh264" "libvpx")|g' "$FFMPEG_HPKBUILD"
    echo "✅ 已添加 libvpx 依赖"
else
    echo "⚠️  未找到预期的 depends 行，尝试其他模式..."
    # 尝试更通用的模式
    sed -i 's|depends=(\([^)]*"openh264"[^)]*\))|depends=(\1 "libvpx")|g' "$FFMPEG_HPKBUILD"
    echo "✅ 已尝试添加 libvpx 依赖（通用模式）"
fi

# 2. 添加 VP8 编译选项
echo "=== 修改 2: 添加 VP8 编译选项 ==="
if grep -q "enable-libopenh264" "$FFMPEG_HPKBUILD"; then
    sed -i 's|--enable-libopenh264|--enable-libopenh264 --enable-decoder=vp8 --enable-parser=vp8 --enable-libvpx --enable-libvpx-vp8-decoder|g' "$FFMPEG_HPKBUILD"
    echo "✅ 已添加 VP8 编译选项"
else
    echo "⚠️  未找到 --enable-libopenh264，查找其他位置..."
    # 查找 configure 行并添加 VP8 选项
    if grep -q "PKG_CONFIG_LIBDIR.*configure" "$FFMPEG_HPKBUILD"; then
        # 在 configure 行的末尾添加 VP8 选项（在 > $buildlog 之前）
        sed -i 's| > \$buildlog| --enable-decoder=vp8 --enable-parser=vp8 --enable-libvpx --enable-libvpx-vp8-decoder > \$buildlog|g' "$FFMPEG_HPKBUILD"
        echo "✅ 已在 configure 行添加 VP8 选项"
    else
        echo "❌ 未找到合适的位置添加 VP8 选项"
    fi
fi

# 显示修改后的配置
echo "=== 修改后的配置 ==="
echo "依赖关系:"
grep "depends=" "$FFMPEG_HPKBUILD"
echo "编译选项:"
grep -E "(enable-decoder=vp8|enable-libvpx)" "$FFMPEG_HPKBUILD" || echo "未找到 VP8 相关配置"

# 验证修改
echo "=== 验证修改结果 ==="
if grep -q "libvpx" "$FFMPEG_HPKBUILD"; then
    echo "✅ libvpx 依赖已添加"
else
    echo "❌ libvpx 依赖添加失败"
fi

if grep -q "enable-decoder=vp8" "$FFMPEG_HPKBUILD"; then
    echo "✅ VP8 解码器已启用"
else
    echo "❌ VP8 解码器启用失败"
fi

if grep -q "enable-libvpx" "$FFMPEG_HPKBUILD"; then
    echo "✅ libvpx 库支持已启用"
else
    echo "❌ libvpx 库支持启用失败"
fi

echo "=== FFmpeg VP8 配置修改完成 ==="

# 显示完整的修改后文件（用于调试）
echo "=== 完整的修改后配置文件 ==="
cat "$FFMPEG_HPKBUILD"
