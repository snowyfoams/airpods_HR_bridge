#!/bin/sh
set -eu

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$ROOT_DIR/AirPodsHRBridge.xcodeproj"
SCHEME="AirPodsHRBridge"
TEAM_ID="${TEAM_ID:-${DEVELOPMENT_TEAM:-}}"
BUILD_DIR="${BUILD_DIR:-/private/tmp/AirPodsHRBridgeBuild}"

if [ "${DEVELOPER_DIR:-}" = "" ]; then
  for candidate in /Applications/Xcode.app /Applications/Xcode*.app; do
    if [ -d "$candidate/Contents/Developer" ]; then
      export DEVELOPER_DIR="$candidate/Contents/Developer"
      break
    fi
  done
fi

if ! xcodebuild -version >/dev/null 2>&1; then
  echo "Full Xcode is not available yet. Install Xcode.app, then rerun this script." >&2
  echo "Current developer directory: $(xcode-select -p 2>/dev/null || echo unknown)" >&2
  exit 2
fi

if [ "$TEAM_ID" = "" ]; then
  TEAM_ID="$(sed -nE 's/[[:space:]]*DEVELOPMENT_TEAM = ([A-Z0-9]+);/\1/p' "$PROJECT/project.pbxproj" | head -n 1 || true)"
fi

set -- \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Debug \
  -destination "generic/platform=iOS" \
  -derivedDataPath "$BUILD_DIR" \
  -allowProvisioningUpdates

if [ "$TEAM_ID" != "" ]; then
  set -- "$@" DEVELOPMENT_TEAM="$TEAM_ID"
fi

xcodebuild "$@" build
