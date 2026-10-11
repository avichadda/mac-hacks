#!/bin/bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PRODUCT_NAME="Mac Hacks"
EXECUTABLE_NAME="MacHacks"
BUNDLE_ID="${BUNDLE_ID:-com.example.machacks}"
VERSION="${VERSION:-1.0.0}"
CODESIGN_IDENTITY="${CODESIGN_IDENTITY:--}"
DIST_DIR="$ROOT/dist"
APP_PATH="$DIST_DIR/$PRODUCT_NAME.app"
DMG_PATH="$DIST_DIR/$PRODUCT_NAME-$VERSION.dmg"
STAGING_DIR="$ROOT/.build/dmg-root"

cd "$ROOT"
swift build -c release
BIN_DIR="$(swift build -c release --show-bin-path)"

rm -rf "$APP_PATH" "$STAGING_DIR"
rm -f "$DMG_PATH"
mkdir -p "$APP_PATH/Contents/MacOS" "$APP_PATH/Contents/Resources" "$STAGING_DIR"

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

hdiutil create \
    -volname "$PRODUCT_NAME" \
    -srcfolder "$STAGING_DIR" \
    -format UDZO \
    -ov \
    "$DMG_PATH"

rm -rf "$STAGING_DIR"

echo "Created:"
echo "  $APP_PATH"
echo "  $DMG_PATH"
