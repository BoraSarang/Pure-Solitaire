#!/bin/bash
# Pure Solitaire 빌드/설치/실행 스크립트
# 사용: ./scripts/build_and_run.sh [debug|release]
set -euo pipefail

CONFIGURATION="${1:-release}"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

APP_NAME="Pure Solitaire"
EXECUTABLE="PureSolitaire"
BUNDLE_ID="com.borasarang.puresolitaire"
VERSION="3.27.0"
DEST="$HOME/Applications/$APP_NAME.app"

echo "== [1/6] 빌드 ($CONFIGURATION) =="
swift build -c "$CONFIGURATION"

echo "== [2/6] 단위 테스트 =="
swift test -c release

echo "== [3/6] .app 번들 구성 =="
BIN=".build/$CONFIGURATION/$EXECUTABLE"
APP="$APP_NAME.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/$EXECUTABLE"
if [ -f "resources/bgm.wav" ]; then
    cp "resources/bgm.wav" "$APP/Contents/Resources/bgm.wav"
    echo "  bgm.wav → Resources 복사됨"
else
    swift scripts/gen_bgm.swift
    cp "resources/bgm.wav" "$APP/Contents/Resources/bgm.wav"
fi

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleName</key>
	<string>$APP_NAME</string>
	<key>CFBundleDisplayName</key>
	<string>순수한 솔리테어</string>
	<key>CFBundleExecutable</key>
	<string>$EXECUTABLE</string>
	<key>CFBundleIdentifier</key>
	<string>$BUNDLE_ID</string>
	<key>CFBundleVersion</key>
	<string>$VERSION</string>
	<key>CFBundleShortVersionString</key>
	<string>$VERSION</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleIconFile</key>
	<string>AppIcon</string>
	<key>CFBundleIconName</key>
	<string>AppIcon</string>
	<key>CFBundleSupportedPlatforms</key>
	<array>
		<string>MacOSX</string>
	</array>
	<key>LSMinimumSystemVersion</key>
	<string>13.0</string>
	<key>LSApplicationCategoryType</key>
	<string>public.app-category.card-games</string>
	<key>NSHighResolutionCapable</key>
	<true/>
	<key>NSPrincipalClass</key>
	<string>NSApplication</string>
	<key>NSHumanReadableCopyright</key>
	<string>© 2026 Pure Solitaire</string>
</dict>
</plist>
PLIST

echo "== [4/6] 아이콘 생성 =="
ICON_SRC="images/AppIcon-1024.png"
if [ ! -f "$ICON_SRC" ]; then
    swift scripts/make_icon.swift
fi
ICONSET="AppIcon.iconset"
rm -rf "$ICONSET"
mkdir -p "$ICONSET"
sips -z 16 16 "$ICON_SRC" --out "$ICONSET/icon_16x16.png" > /dev/null
sips -z 32 32 "$ICON_SRC" --out "$ICONSET/icon_16x16@2x.png" > /dev/null
sips -z 32 32 "$ICON_SRC" --out "$ICONSET/icon_32x32.png" > /dev/null
sips -z 64 64 "$ICON_SRC" --out "$ICONSET/icon_32x32@2x.png" > /dev/null
sips -z 128 128 "$ICON_SRC" --out "$ICONSET/icon_128x128.png" > /dev/null
sips -z 256 256 "$ICON_SRC" --out "$ICONSET/icon_128x128@2x.png" > /dev/null
sips -z 256 256 "$ICON_SRC" --out "$ICONSET/icon_256x256.png" > /dev/null
sips -z 512 512 "$ICON_SRC" --out "$ICONSET/icon_256x256@2x.png" > /dev/null
sips -z 512 512 "$ICON_SRC" --out "$ICONSET/icon_512x512.png" > /dev/null
cp "$ICON_SRC" "$ICONSET/icon_512x512@2x.png"
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"
rm -rf "$ICONSET"

echo "== [5/6] 코드 서명 (ad-hoc) =="
codesign --force --deep --sign - "$APP"

echo "== [6/6] 설치 및 실행 =="
rm -rf "$DEST"
cp -R "$APP" "$DEST"
rm -rf "$APP"
echo "설치 완료: $DEST"
open "$DEST"
