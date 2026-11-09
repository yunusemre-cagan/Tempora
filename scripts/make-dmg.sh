#!/bin/bash
# Builds a Release version of Tempora and packages it into a drag-to-install DMG.
#
#   scripts/make-dmg.sh                      # signs with whatever identity Xcode picks (Apple Development)
#   SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" scripts/make-dmg.sh
#   SIGN_IDENTITY="Developer ID Application: …" NOTARY_PROFILE=tempora-notary scripts/make-dmg.sh
#
# NOTARY_PROFILE is a keychain profile created once with:
#   xcrun notarytool store-credentials tempora-notary --apple-id <id> --team-id <TEAMID> --password <app-specific-password>
#
# Only a Developer ID signature + notarization (paid Apple Developer Program) lets other Macs open the
# app without a Gatekeeper warning. Without them the DMG still works, but users must approve the app once
# in System Settings > Privacy & Security > "Open Anyway".
set -euo pipefail

cd "$(dirname "$0")/.."
APP_NAME="Tempora"
BUILD_DIR="build-release"
DIST_DIR="dist"
STAGING="$BUILD_DIR/dmg-staging"

echo "▸ Building $APP_NAME (Release)…"
SIGN_ARGS=()
if [[ -n "${SIGN_IDENTITY:-}" ]]; then
  SIGN_ARGS=(CODE_SIGN_STYLE=Manual "CODE_SIGN_IDENTITY=$SIGN_IDENTITY" "OTHER_CODE_SIGN_FLAGS=--timestamp" ENABLE_HARDENED_RUNTIME=YES)
fi
rm -rf "$BUILD_DIR"
xcodebuild -project Tempora.xcodeproj -scheme Tempora -configuration Release \
  -derivedDataPath "$BUILD_DIR" -allowProvisioningUpdates ARCHS="arm64 x86_64" ONLY_ACTIVE_ARCH=NO ${SIGN_ARGS[@]+"${SIGN_ARGS[@]}"} build -quiet

APP="$BUILD_DIR/Build/Products/Release/$APP_NAME.app"
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP/Contents/Info.plist")
DMG="$DIST_DIR/$APP_NAME-$VERSION.dmg"
mkdir -p "$DIST_DIR"
codesign --verify --deep --strict "$APP"
echo "▸ Architectures: $(lipo -archs "$APP/Contents/MacOS/$APP_NAME")"
echo "▸ Signed with: $(codesign -dvv "$APP" 2>&1 | grep -m1 'Authority=' | cut -d= -f2)"

echo "▸ Creating $DMG…"
rm -rf "$STAGING" "$DMG" "$BUILD_DIR/rw.dmg"
mkdir -p "$STAGING/.background"
cp -R "$APP" "$STAGING/"
ln -s /Applications "$STAGING/Applications"
cp scripts/dmg-background.png "$STAGING/.background/background.png"

hdiutil create -quiet -volname "$APP_NAME" -srcfolder "$STAGING" -fs HFS+ -format UDRW -ov "$BUILD_DIR/rw.dmg"
MOUNT_POINT=$(hdiutil attach -readwrite -noverify -noautoopen "$BUILD_DIR/rw.dmg" | grep -o '/Volumes/.*$' | head -1)

# Lay out the Finder window (icon positions + background). Best effort: needs Finder automation.
osascript <<OSA || echo "  (couldn't style the window; the DMG still works)"
tell application "Finder"
  tell disk "$APP_NAME"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set bounds of container window to {200, 120, 860, 520}
    set opts to the icon view options of container window
    set arrangement of opts to not arranged
    set icon size of opts to 112
    set text size of opts to 13
    set background picture of opts to file ".background:background.png"
    set position of item "$APP_NAME.app" of container window to {170, 205}
    set position of item "Applications" of container window to {490, 205}
    close
    open
    update without registering applications
    delay 1
    close
  end tell
end tell
OSA

sync
hdiutil detach -quiet "$MOUNT_POINT"
hdiutil convert -quiet "$BUILD_DIR/rw.dmg" -format UDZO -imagekey zlib-level=9 -o "$DMG"
[[ -n "${SIGN_IDENTITY:-}" ]] && codesign --force --timestamp --sign "$SIGN_IDENTITY" "$DMG"

if [[ -n "${NOTARY_PROFILE:-}" ]]; then
  echo "▸ Notarizing (this takes a few minutes)…"
  xcrun notarytool submit "$DMG" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$DMG"
fi

shasum -a 256 "$DMG" | tee "$DMG.sha256"
echo "✓ Done: $DMG"
