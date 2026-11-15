#!/bin/bash
# Usage: scripts/package-unnotarized.sh /absolute/path/to/ByteBloom.app /absolute/output/directory
set -euo pipefail
app="${1:?Provide the Release app path}"
output="${2:?Provide the output directory}"
[[ "$app" = /* && "$output" = /* ]]
plist="$app/Contents/Info.plist"
test "$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$plist")" = com.juswilvel.ByteBloom
test "$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$plist")" = 0.1.1
test "$(/usr/libexec/PlistBuddy -c 'Print CFBundleVersion' "$plist")" = 2
test "$(/usr/libexec/PlistBuddy -c 'Print LSMinimumSystemVersion' "$plist")" = 14.0
archs=$(lipo -archs "$app/Contents/MacOS/ByteBloom")
[[ "$archs" = "x86_64 arm64" || "$archs" = "arm64 x86_64" ]]
codesign --verify --deep --strict "$app"
guide="$(cd "$(dirname "$0")/../docs" && pwd)/INSTALL-UNNOTARIZED.md"
mkdir -p "$output"
name=ByteBloom-0.1.1-macOS-UNNOTARIZED.dmg
test ! -e "$output/$name"
stage=$(mktemp -d)
trap 'rm -rf -- "$stage"' EXIT
ditto "$app" "$stage/ByteBloom.app"
ln -s /Applications "$stage/Applications"
cp "$guide" "$stage/Installation.md"
hdiutil create -volname 'ByteBloom 0.1.1 UNNOTARIZED' -srcfolder "$stage" -format UDZO "$output/$name"
hdiutil verify "$output/$name"
(cd "$output" && shasum -a 256 "$name" > "$name.sha256")
