#!/usr/bin/env bash
# Builds a standalone Stash.app that can be moved to /Applications on a Mac.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Stash"
BUNDLE_ID="${BUNDLE_ID:-com.stash.desktop}"
VERSION="${VERSION:-1.0.0}"
BUILD_NUMBER="${BUILD_NUMBER:-1}"
ARCH="${ARCH:-arm64}"
DIST_DIR="${ROOT_DIR}/dist"
APP_PATH="${DIST_DIR}/${APP_NAME}.app"

command -v swift >/dev/null || { echo "Swift/Xcode is required. Install Xcode 15.3 or later and retry." >&2; exit 1; }

rm -rf "${APP_PATH}"
mkdir -p "${APP_PATH}/Contents/MacOS" "${APP_PATH}/Contents/Resources"

cd "${ROOT_DIR}"
swift build -c release --arch "${ARCH}"
BIN_DIR="$(swift build -c release --arch "${ARCH}" --show-bin-path)"
install -m 755 "${BIN_DIR}/${APP_NAME}" "${APP_PATH}/Contents/MacOS/${APP_NAME}"

cat > "${APP_PATH}/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleDisplayName</key><string>${APP_NAME}</string>
  <key>CFBundleExecutable</key><string>${APP_NAME}</string>
  <key>CFBundleIdentifier</key><string>${BUNDLE_ID}</string>
  <key>CFBundleName</key><string>${APP_NAME}</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>${VERSION}</string>
  <key>CFBundleVersion</key><string>${BUILD_NUMBER}</string>
  <key>LSApplicationCategoryType</key><string>public.app-category.utilities</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSUIElement</key><true/>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSHumanReadableCopyright</key><string>Copyright © 2026 Stash</string>
</dict></plist>
PLIST

if [[ -n "${CODESIGN_IDENTITY:-}" ]]; then
  echo "Signing ${APP_NAME}.app with hardened runtime…"
  codesign --force --sign "${CODESIGN_IDENTITY}" --options runtime --timestamp "${APP_PATH}"
  codesign --verify --deep --strict --verbose=2 "${APP_PATH}"
else
  echo "Created an unsigned development build at ${APP_PATH}."
  echo "For release distribution, rerun with CODESIGN_IDENTITY='Developer ID Application: Your Name (TEAMID)'."
fi

echo
echo "App bundle created: ${APP_PATH}"
echo "To install locally: open '${DIST_DIR}' and drag ${APP_NAME}.app into /Applications."
