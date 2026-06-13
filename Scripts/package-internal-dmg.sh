#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

APP_NAME="Lumiere"
PROJECT="Lumiere.xcodeproj"
SCHEME="Lumiere"
CONFIGURATION="Release"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-build/InternalReleaseDerivedData}"
BUILD_DIR="${BUILD_DIR:-build}"
STAGE_DIR="${STAGE_DIR:-$BUILD_DIR/internal-dmg-staging}"
DMG_PATH="${DMG_PATH:-$BUILD_DIR/Lumiere-Internal-AdHoc.dmg}"
SHA_PATH="${SHA_PATH:-$DMG_PATH.sha256}"
APP_PATH="$DERIVED_DATA_PATH/Build/Products/$CONFIGURATION/$APP_NAME.app"
STAGED_APP="$STAGE_DIR/$APP_NAME.app"

printf '%s\n' "== Lumiere internal ad-hoc DMG package =="
printf '%s\n' "Scope: internal/private testing only. No Developer ID signing. No notarization. No GitHub Release."
printf '%s\n' ""

xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  clean build

if [[ ! -d "$APP_PATH" ]]; then
  printf 'ERROR: built app not found: %s\n' "$APP_PATH" >&2
  exit 1
fi

printf '%s\n' "== Verify built app signature =="
codesign --verify --deep --strict --verbose=2 "$APP_PATH"
codesign -dv --verbose=4 "$APP_PATH" 2>&1 | grep -E 'Identifier=|Signature=|TeamIdentifier=|Format=|CDHash='

SIGNATURE="$(codesign -dv "$APP_PATH" 2>&1 | awk -F= '/^Signature=/{print $2}')"
TEAM_IDENTIFIER="$(codesign -dv "$APP_PATH" 2>&1 | awk -F= '/^TeamIdentifier=/{print $2}')"
if [[ "$SIGNATURE" != "adhoc" ]]; then
  printf 'ERROR: expected ad-hoc signature, got: %s\n' "$SIGNATURE" >&2
  exit 1
fi
if [[ "$TEAM_IDENTIFIER" != "not set" ]]; then
  printf 'ERROR: expected no TeamIdentifier, got: %s\n' "$TEAM_IDENTIFIER" >&2
  exit 1
fi

printf '%s\n' "== Verify icon/logo resources =="
/usr/libexec/PlistBuddy -c 'Print :CFBundleIconName' "$APP_PATH/Contents/Info.plist" | grep -x 'AppIcon'
/usr/libexec/PlistBuddy -c 'Print :CFBundleIconFile' "$APP_PATH/Contents/Info.plist" | grep -x 'AppIcon'
test -s "$APP_PATH/Contents/Resources/AppIcon.icns"
test -s "$APP_PATH/Contents/Resources/LumiereLogo.svg"
stat -f 'AppIcon.icns bytes=%z' "$APP_PATH/Contents/Resources/AppIcon.icns"
stat -f 'LumiereLogo.svg bytes=%z' "$APP_PATH/Contents/Resources/LumiereLogo.svg"

printf '%s\n' "== Stage DMG contents =="
rm -rf "$STAGE_DIR" "$DMG_PATH" "$SHA_PATH"
mkdir -p "$STAGE_DIR"
ditto "$APP_PATH" "$STAGED_APP"
ln -s /Applications "$STAGE_DIR/Applications"

printf '%s\n' "== Verify staged app signature =="
codesign --verify --deep --strict --verbose=2 "$STAGED_APP"

printf '%s\n' "== Create unsigned/ad-hoc internal DMG =="
hdiutil create \
  -volname "Lumiere Internal" \
  -srcfolder "$STAGE_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

printf '%s\n' "== Verify DMG =="
hdiutil verify "$DMG_PATH"

printf '%s\n' "== SHA256 =="
shasum -a 256 "$DMG_PATH" | tee "$SHA_PATH"

printf '%s\n' "== Artifacts =="
stat -f 'DMG path=%N bytes=%z' "$DMG_PATH"
stat -f 'SHA path=%N bytes=%z' "$SHA_PATH"
