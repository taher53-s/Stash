#!/usr/bin/env bash
# Runs basic release checks on a macOS-built Stash.app before sharing it with users.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_PATH="${ROOT_DIR}/dist/Stash.app"

[[ -d "${APP_PATH}" ]] || { echo "Build dist/Stash.app first." >&2; exit 1; }
plutil -lint "${APP_PATH}/Contents/Info.plist"
codesign --verify --deep --strict --verbose=2 "${APP_PATH}"
echo "Manual smoke test: launch Stash.app, grant Accessibility access, shake-drop a local file, use Quick Look and the share menu, then open Settings."
