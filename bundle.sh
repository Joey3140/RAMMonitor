#!/bin/bash
set -e
cd "$(dirname "$0")"

echo "Building RAMMonitor..."
swift build -c release 2>&1
APP="RAMMonitor.app"
BUNDLE_ID="com.local.RAMMonitor"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp .build/release/RAMMonitor "$APP/Contents/MacOS/RAMMonitor"
cp Resources/Info.plist "$APP/Contents/Info.plist"

# Sign with a STABLE Developer ID so TCC permissions persist across rebuilds
# (ad-hoc signatures change identity every build and reset consent).
#   --options runtime : hardened runtime    --timestamp : secure Apple timestamp
SIGN_ID="Developer ID Application: Joseph Drury (4MMDJ2N969)"
codesign --force --sign "$SIGN_ID" --options runtime --timestamp \
    --identifier "$BUNDLE_ID" "$APP" 2>&1 | tail -2 || echo "codesign failed (continuing)"
echo "✓ Built & signed: $APP"

# Quit any running instance so the new binary takes over cleanly.
if pgrep -f "RAMMonitor.app/Contents/MacOS/RAMMonitor" >/dev/null 2>&1; then
    osascript -e "tell application id \"$BUNDLE_ID\" to quit" 2>/dev/null || true
    for _ in $(seq 1 25); do
        pgrep -f "RAMMonitor.app/Contents/MacOS/RAMMonitor" >/dev/null || break
        sleep 0.2
    done
    pkill -9 -f "RAMMonitor.app/Contents/MacOS/RAMMonitor" 2>/dev/null || true
fi

# Install to /Applications and relaunch
rm -rf "/Applications/$APP"
cp -R "$APP" "/Applications/$APP"
LSREG=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
"$LSREG" -f "/Applications/$APP" 2>/dev/null || true
open "/Applications/$APP"
echo "✓ Installed & launched: /Applications/$APP"
