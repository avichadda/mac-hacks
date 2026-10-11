#!/bin/bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PRODUCT_NAME="Mac Hacks"
VOLUME_NAME="Mac Hacks Installer"
EXECUTABLE_NAME="MacHacks"
BUNDLE_ID="${BUNDLE_ID:-com.example.machacks}"
VERSION="${VERSION:-1.0.0}"
CODESIGN_IDENTITY="${CODESIGN_IDENTITY:--}"
DIST_DIR="$ROOT/dist"
APP_PATH="$DIST_DIR/$PRODUCT_NAME.app"
DMG_PATH="$DIST_DIR/$PRODUCT_NAME-$VERSION.dmg"
STAGING_DIR="$ROOT/.build/dmg-root"
ASSET_DIR="$ROOT/.build/dmg-assets"
ICONSET_DIR="$ROOT/.build/AppIcon.iconset"
MOUNT_DIR="/Volumes/$VOLUME_NAME"
RW_DMG_PATH="$ROOT/.build/$PRODUCT_NAME-$VERSION-rw.dmg"

cd "$ROOT"
swift build -c release
BIN_DIR="$(swift build -c release --show-bin-path)"

if mount | grep -Fq "on $MOUNT_DIR "; then
    hdiutil detach "$MOUNT_DIR"
fi

rm -rf "$APP_PATH" "$STAGING_DIR" "$ASSET_DIR" "$ICONSET_DIR"
rm -f "$DMG_PATH" "$RW_DMG_PATH"
mkdir -p \
    "$APP_PATH/Contents/MacOS" \
    "$APP_PATH/Contents/Resources" \
    "$STAGING_DIR/.background" \
    "$ASSET_DIR" \
    "$ICONSET_DIR"

swift "$ROOT/scripts/generate-dmg-assets.swift" "$ASSET_DIR"

sips -z 16 16 "$ASSET_DIR/AppIcon-1024.png" --out "$ICONSET_DIR/icon_16x16.png" >/dev/null
sips -z 32 32 "$ASSET_DIR/AppIcon-1024.png" --out "$ICONSET_DIR/icon_16x16@2x.png" >/dev/null
sips -z 32 32 "$ASSET_DIR/AppIcon-1024.png" --out "$ICONSET_DIR/icon_32x32.png" >/dev/null
sips -z 64 64 "$ASSET_DIR/AppIcon-1024.png" --out "$ICONSET_DIR/icon_32x32@2x.png" >/dev/null
sips -z 128 128 "$ASSET_DIR/AppIcon-1024.png" --out "$ICONSET_DIR/icon_128x128.png" >/dev/null
sips -z 256 256 "$ASSET_DIR/AppIcon-1024.png" --out "$ICONSET_DIR/icon_128x128@2x.png" >/dev/null
sips -z 256 256 "$ASSET_DIR/AppIcon-1024.png" --out "$ICONSET_DIR/icon_256x256.png" >/dev/null
sips -z 512 512 "$ASSET_DIR/AppIcon-1024.png" --out "$ICONSET_DIR/icon_256x256@2x.png" >/dev/null
sips -z 512 512 "$ASSET_DIR/AppIcon-1024.png" --out "$ICONSET_DIR/icon_512x512.png" >/dev/null
cp "$ASSET_DIR/AppIcon-1024.png" "$ICONSET_DIR/icon_512x512@2x.png"
iconutil -c icns "$ICONSET_DIR" -o "$APP_PATH/Contents/Resources/AppIcon.icns"

cp "$BIN_DIR/$EXECUTABLE_NAME" "$APP_PATH/Contents/MacOS/$EXECUTABLE_NAME"
cp "$ROOT/README.md" "$APP_PATH/Contents/Resources/catalog.md"

cat > "$APP_PATH/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>$EXECUTABLE_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleName</key>
    <string>$PRODUCT_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

codesign --force --deep --sign "$CODESIGN_IDENTITY" "$APP_PATH"

ditto "$APP_PATH" "$STAGING_DIR/$PRODUCT_NAME.app"
ln -s /Applications "$STAGING_DIR/Applications"
cp "$ASSET_DIR/dmg-background.png" "$STAGING_DIR/.background/background.png"

hdiutil create \
    -volname "$VOLUME_NAME" \
    -srcfolder "$STAGING_DIR" \
    -fs HFS+ \
    -format UDRW \
    -ov \
    "$RW_DMG_PATH"

hdiutil attach \
    "$RW_DMG_PATH" \
    -readwrite \
    -noverify \
    -noautoopen >/dev/null

if [[ ! -d "$MOUNT_DIR" ]]; then
    echo "Expected mounted volume at $MOUNT_DIR" >&2
    exit 1
fi

osascript <<EOF
set backgroundFile to POSIX file "$MOUNT_DIR/.background/background.png" as alias
tell application "Finder"
    tell disk "$VOLUME_NAME"
        open
        delay 1
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set pathbar visible of container window to false
        set sidebar width of container window to 0
        set the bounds of container window to {180, 120, 900, 610}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 104
        set text size of viewOptions to 13
        set background picture of viewOptions to backgroundFile
        set position of item "$PRODUCT_NAME.app" to {185, 225}
        set position of item "Applications" to {535, 225}
        update without registering applications
        delay 2
        close
    end tell
end tell
EOF

sync
hdiutil detach "$MOUNT_DIR" >/dev/null

hdiutil convert \
    "$RW_DMG_PATH" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -ov \
    -o "$DMG_PATH" >/dev/null

rm -rf "$STAGING_DIR" "$ASSET_DIR" "$ICONSET_DIR"
rm -f "$RW_DMG_PATH"

echo "Created:"
echo "  $APP_PATH"
echo "  $DMG_PATH"
