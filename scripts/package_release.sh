#!/bin/bash
# Pure Solitaire 릴리스 .app 번들 패키징 + zip 생성
# 사용: bash scripts/package_release.sh [version]
set -euo pipefail

VERSION="${1:-3.20.0}"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

EXECUTABLE="PureSolitaire"
APP_NAME="Pure Solitaire"
BUNDLE_ID="com.borasarang.puresolitaire"
BIN=".build/release/$EXECUTABLE"
APP="$APP_NAME.app"

echo "== [1/4] .app 번들 구성 =="
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/$EXECUTABLE"
if [ -f "resources/bgm.wav" ]; then
  cp "resources/bgm.wav" "$APP/Contents/Resources/bgm.wav"
fi

echo "== [2/4] Info.plist 생성 =="
APP_NAME="$APP_NAME" EXECUTABLE="$EXECUTABLE" BUNDLE_ID="$BUNDLE_ID" VERSION="$VERSION" python3 scripts/gen_info_plist.py "$APP"

echo "== [3/4] 아이콘 + 코드 서명 =="
ICONSET="./AppIcon.iconset"
cp "images/AppIcon-1024.png" "$APP/Contents/Resources/AppIcon.png"
rm -rf "$ICONSET"
mkdir -p "$ICONSET"
sips -z 16 16 "images/AppIcon-1024.png" --out "$ICONSET/icon_16x16.png" > /dev/null
sips -z 32 32 "images/AppIcon-1024.png" --out "$ICONSET/icon_16x16@2x.png" > /dev/null
sips -z 32 32 "images/AppIcon-1024.png" --out "$ICONSET/icon_32x32.png" > /dev/null
sips -z 64 64 "images/AppIcon-1024.png" --out "$ICONSET/icon_32x32@2x.png" > /dev/null
sips -z 128 128 "images/AppIcon-1024.png" --out "$ICONSET/icon_128x128.png" > /dev/null
sips -z 256 256 "images/AppIcon-1024.png" --out "$ICONSET/icon_128x128@2x.png" > /dev/null
sips -z 256 256 "images/AppIcon-1024.png" --out "$ICONSET/icon_256x256.png" > /dev/null
sips -z 512 512 "images/AppIcon-1024.png" --out "$ICONSET/icon_256x256@2x.png" > /dev/null
sips -z 512 512 "images/AppIcon-1024.png" --out "$ICONSET/icon_512x512.png" > /dev/null
cp "images/AppIcon-1024.png" "$ICONSET/icon_512x512@2x.png"
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"
rm -rf "$ICONSET"
codesign --force --deep --sign - "$APP"

echo "== [4/4] zip 패키징 =="
ZIP="Pure-Solitaire-$VERSION-macos.zip"
rm -f "$ZIP"
ditto -c -k --keepParent "$APP" "$ZIP"
rm -rf "$APP"
echo "완료: $ZIP"