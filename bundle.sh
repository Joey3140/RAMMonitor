#!/bin/bash
set -e
echo "Building RAMMonitor..."
swift build -c release 2>&1
APP="RAMMonitor.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp .build/release/RAMMonitor "$APP/Contents/MacOS/RAMMonitor"
cp Resources/Info.plist "$APP/Contents/Info.plist"
echo "✓ Built: $APP"
echo "  Run with: open $APP"
