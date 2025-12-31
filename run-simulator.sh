#!/bin/bash

# TAG2 iOS Simulator Runner
# Usage: ./run-simulator.sh [device_name]
# Example: ./run-simulator.sh "iPhone 17 Pro"

# Default device
DEVICE_NAME="${1:-iPhone 15}"
PROJECT_DIR="/Users/ozz/Desktop/TAG2"
BUNDLE_ID="mx.itgroup.tag2"

echo "🏗️  Building TAG2 for $DEVICE_NAME..."
cd "$PROJECT_DIR"

# Build the project
xcodebuild -project tag2.xcodeproj \
    -scheme tag2 \
    -destination "platform=iOS Simulator,name=$DEVICE_NAME" \
    build 2>&1 | grep -E "(BUILD|error:|warning:.*error)" | tail -5

if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

echo "✅ Build succeeded!"

# Find the app path - specifically in Build/Products, not Index
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/tag2-*/Build/Products/Debug-iphonesimulator -name "tag2.app" -type d 2>/dev/null | head -1)

if [ -z "$APP_PATH" ]; then
    echo "❌ Could not find built app"
    exit 1
fi

echo "📍 App found at: $APP_PATH"

echo "📱 Opening Simulator..."
open -a Simulator

# Wait for simulator to boot
sleep 2

echo "📲 Installing app..."
xcrun simctl install booted "$APP_PATH"

if [ $? -ne 0 ]; then
    echo "❌ Installation failed!"
    exit 1
fi

echo "🚀 Launching TAG2..."
xcrun simctl launch booted "$BUNDLE_ID"

echo ""
echo "✨ TAG2 is now running in the simulator!"
echo ""
