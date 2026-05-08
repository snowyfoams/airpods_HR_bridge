#!/bin/sh
set -eu

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$ROOT_DIR/AirPodsHRBridge.xcodeproj"
SCHEME="AirPodsHRBridge"
BUILD_DIR="${BUILD_DIR:-/private/tmp/AirPodsHRBridgeBuild}"
BUNDLE_ID="${BUNDLE_ID:-}"
TEAM_ID="${TEAM_ID:-${DEVELOPMENT_TEAM:-}}"

find_xcode() {
  if [ "${DEVELOPER_DIR:-}" != "" ] && [ -x "$DEVELOPER_DIR/usr/bin/xcodebuild" ]; then
    return 0
  fi

  for candidate in /Applications/Xcode.app /Applications/Xcode*.app; do
    if [ -d "$candidate/Contents/Developer" ]; then
      export DEVELOPER_DIR="$candidate/Contents/Developer"
      return 0
    fi
  done

  return 1
}

fail_missing_xcode() {
  cat >&2 <<EOF
Full Xcode is not available yet.

Install Xcode.app into /Applications, launch it once, accept the license, and let it finish installing platform components.
Current developer directory: $(xcode-select -p 2>/dev/null || echo unknown)
EOF
  exit 2
}

find_device_id() {
  if [ "${DEVICE_ID:-}" != "" ]; then
    printf '%s\n' "$DEVICE_ID"
    return 0
  fi

  local_id="$(xcrun xctrace list devices 2>/dev/null \
    | awk '/^== Simulators ==/{exit} /iPhone|iPad|iPod/{print}' \
    | sed -nE 's/.*\(([0-9A-Fa-f-]{25,})\).*/\1/p' \
    | head -n 1 || true)"

  if [ "$local_id" != "" ]; then
    printf '%s\n' "$local_id"
    return 0
  fi

  xcrun devicectl list devices 2>/dev/null \
    | sed -nE 's/.*([0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}).*/\1/p' \
    | head -n 1
}

if ! find_xcode || ! xcodebuild -version >/dev/null 2>&1; then
  fail_missing_xcode
fi

DEVICE_ID="$(find_device_id || true)"
if [ "$DEVICE_ID" = "" ]; then
  cat >&2 <<EOF
No connected iPhone UDID was detected.

Connect the iPhone by USB, unlock it, tap Trust This Computer, enable Developer Mode if prompted, then rerun.
You can also pass the UDID manually:

  DEVICE_ID=<iPhone UDID> TEAM_ID=$TEAM_ID Scripts/deploy-to-iphone.sh
EOF
  xcrun xctrace list devices >&2 || true
  exit 2
fi

if [ "$TEAM_ID" = "" ]; then
  TEAM_ID="$(sed -nE 's/[[:space:]]*DEVELOPMENT_TEAM = ([A-Z0-9]+);/\1/p' "$PROJECT/project.pbxproj" | head -n 1 || true)"
fi

if [ "$TEAM_ID" = "" ]; then
  TEAM_ID="$(security find-identity -v -p codesigning 2>/dev/null | sed -nE 's/.*"Apple Development:.*\(([A-Z0-9]{10})\)".*/\1/p' | head -n 1 || true)"
fi

if [ "$BUNDLE_ID" = "" ]; then
  BUNDLE_ID="$(sed -nE 's/[[:space:]]*PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);/\1/p' "$PROJECT/project.pbxproj" | head -n 1 || true)"
fi

if [ "$BUNDLE_ID" = "" ]; then
  echo "Could not detect PRODUCT_BUNDLE_IDENTIFIER. Pass BUNDLE_ID=<your.bundle.id> explicitly." >&2
  exit 2
fi

echo "Using Xcode: ${DEVELOPER_DIR:-$(xcode-select -p)}"
echo "Using iPhone: $DEVICE_ID"
if [ "$TEAM_ID" != "" ]; then
  echo "Using Team:  $TEAM_ID"
else
  echo "Using Team:  automatic/project setting"
fi
echo "Bundle ID:   $BUNDLE_ID"

set -- \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Debug \
  -destination "platform=iOS,id=$DEVICE_ID" \
  -derivedDataPath "$BUILD_DIR" \
  -allowProvisioningUpdates \
  -allowProvisioningDeviceRegistration

if [ "$TEAM_ID" != "" ]; then
  set -- "$@" DEVELOPMENT_TEAM="$TEAM_ID"
fi

xcodebuild "$@" build

APP_PATH="$BUILD_DIR/Build/Products/Debug-iphoneos/AirPodsHRBridge.app"

if [ ! -d "$APP_PATH" ]; then
  echo "Build succeeded but app bundle was not found at $APP_PATH" >&2
  exit 1
fi

xcrun devicectl device install app --device "$DEVICE_ID" "$APP_PATH"
xcrun devicectl device process launch --device "$DEVICE_ID" "$BUNDLE_ID" || true

cat <<EOF

Installed AirPods HR Bridge on the iPhone.

For HR Glance:
1. Wear AirPods, open the app, and tap Start HR Glance.
2. Watch BPM in the app, on the Lock Screen, or in the Dynamic Island.
3. Tap Stop HR Glance when done; the workout is discarded.

For one-tap widget launch:
1. Long-press the Home Screen or Lock Screen and add the HR Glance widget.
2. Tap the widget once to start HR Glance; tap it again to stop.
3. The widget shows Monitoring; the Live Activity / Dynamic Island is the real-time display.

For App Store demos:
1. Tap Start Demo Mode to simulate BPM without AirPods or HealthKit.
2. Demo Mode also advertises simulated BLE Heart Rate Service data.
3. Tap Stop Demo Mode when done.

For first Edge 530 pairing:
1. Keep the app open and the screen unlocked.
2. Tap Start BLE Bridge and allow Health permissions.
3. Wait until the app shows BPM and BLE is Advertising or Broadcasting.
4. On Edge 530: Settings > Sensors > Add Sensor > Heart Rate.
5. Select AirPodsHRBridge.
EOF
