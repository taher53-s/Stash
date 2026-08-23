#!/usr/bin/env bash
# Submits a Developer ID-signed Stash.app for Apple notarization, then staples the returned ticket.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_PATH="${ROOT_DIR}/dist/Stash.app"
ZIP_PATH="${ROOT_DIR}/dist/Stash-notarization.zip"
PROFILE="${NOTARY_KEYCHAIN_PROFILE:-}"

[[ -d "${APP_PATH}" ]] || { echo "Build dist/Stash.app first with Scripts/build_app.sh." >&2; exit 1; }
[[ -n "${PROFILE}" ]] || { echo "Set NOTARY_KEYCHAIN_PROFILE to a notarytool keychain profile." >&2; exit 1; }

codesign --verify --deep --strict --verbose=2 "${APP_PATH}"
rm -f "${ZIP_PATH}"
ditto -c -k --keepParent "${APP_PATH}" "${ZIP_PATH}"
xcrun notarytool submit "${ZIP_PATH}" --keychain-profile "${PROFILE}" --wait
xcrun stapler staple "${APP_PATH}"
spctl --assess --type execute --verbose=4 "${APP_PATH}"

echo "Notarized and stapled: ${APP_PATH}"
