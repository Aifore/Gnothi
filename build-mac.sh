#!/bin/bash
# 一键编译 Gnothi 的 Mac 版，并安装到「应用程序」文件夹
# 用法：在终端里进入本目录，执行  ./build-mac.sh
# 需要：macOS 14+，Xcode 16+（首次请先打开一次 Xcode 完成组件安装）
set -euo pipefail
cd "$(dirname "$0")"

echo "▶︎ 正在编译 Gnothi（macOS）…"
xcodebuild \
  -project Gnothi.xcodeproj \
  -scheme Gnothi \
  -configuration Debug \
  -destination 'platform=macOS' \
  -derivedDataPath build/DerivedData \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGN_STYLE=Manual \
  DEVELOPMENT_TEAM="" \
  build | grep -E "error:|warning: .*Gnothi/|BUILD (SUCCEEDED|FAILED)" || true

APP="build/DerivedData/Build/Products/Debug/Gnothi.app"
if [ ! -d "$APP" ]; then
  echo "✗ 编译失败。请把上面的 error 信息发给 Claude。"
  echo "  也可以用 Xcode 打开 Gnothi.xcodeproj，选择「My Mac」后按 ⌘R 查看详细错误。"
  exit 1
fi

rm -rf "/Applications/Gnothi.app"
cp -R "$APP" /Applications/
echo "✓ 已安装到 /Applications/Gnothi.app"
open "/Applications/Gnothi.app"
