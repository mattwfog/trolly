#!/bin/bash
set -e

APP_NAME="Trolly"
BUNDLE_DIR=".build/${APP_NAME}.app"
CONTENTS_DIR="${BUNDLE_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "Building ${APP_NAME}..."
swift build -c release

echo "Creating app bundle..."
rm -rf "${BUNDLE_DIR}"
mkdir -p "${MACOS_DIR}" "${RESOURCES_DIR}"

cp ".build/release/${APP_NAME}" "${MACOS_DIR}/${APP_NAME}"

cat > "${CONTENTS_DIR}/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>Trolly</string>
    <key>CFBundleDisplayName</key>
    <string>Trolly</string>
    <key>CFBundleIdentifier</key>
    <string>com.trolly.app</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleExecutable</key>
    <string>Trolly</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSScreenCaptureUsageDescription</key>
    <string>Trolly needs to capture your screen for recording.</string>
    <key>NSCameraUsageDescription</key>
    <string>Trolly uses your camera for webcam overlay.</string>
    <key>NSMicrophoneUsageDescription</key>
    <string>Trolly records audio from your microphone.</string>
    <key>LSUIElement</key>
    <false/>
</dict>
</plist>
PLIST

echo "Signing app bundle..."
codesign --force --deep --sign - "${BUNDLE_DIR}"

echo "Done! App bundle at: ${BUNDLE_DIR}"
echo "To install: cp -r ${BUNDLE_DIR} /Applications/"
echo "To run: open ${BUNDLE_DIR}"
