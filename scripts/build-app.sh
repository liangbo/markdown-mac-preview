#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Markdown Mac Preview"
BUNDLE_DIR="$ROOT_DIR/build/$APP_NAME.app"
CONTENTS_DIR="$BUNDLE_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"

cd "$ROOT_DIR"
swift build -c release --product MarkdownMacPreview

rm -rf "$BUNDLE_DIR"
mkdir -p "$MACOS_DIR"
cp "$ROOT_DIR/.build/release/MarkdownMacPreview" "$MACOS_DIR/MarkdownMacPreview"

cat > "$CONTENTS_DIR/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>MarkdownMacPreview</string>
  <key>CFBundleIdentifier</key>
  <string>com.liangbo.markdown-mac-preview</string>
  <key>CFBundleName</key>
  <string>Markdown Mac Preview</string>
  <key>CFBundleDisplayName</key>
  <string>Markdown Mac Preview</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

echo "Created $BUNDLE_DIR"
