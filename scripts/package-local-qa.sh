#!/bin/bash
# Usage: scripts/package-local-qa.sh /absolute/path/to/ByteBloom.app /absolute/output/directory
# Packages an already-built app. This does not sign, notarize, or publish.
set -euo pipefail
app="$1"
output="$2"
[[ "$app" = /* && "$output" = /* ]]
test -d "$app"
test "$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$app/Contents/Info.plist")" = com.juswilvel.ByteBloom
codesign --verify --deep --strict "$app"
mkdir -p "$output"
stage=$(mktemp -d "$output/qa-stage.XXXXXX")
ditto "$app" "$stage/ByteBloom.app"
ln -s /Applications "$stage/Applications"
printf '%s\n' 'LOCAL QA ONLY — ad-hoc signed, not notarized.' 'Not a trusted public installer. Intended for owner testing on the development Mac.' > "$stage/LOCAL-QA-ONLY.txt"
dmg="$output/ByteBloom-0.1.1-macOS-LOCAL-QA.dmg"
test ! -e "$dmg"
hdiutil create -volname 'ByteBloom 0.1.1 Local QA' -srcfolder "$stage" -format UDZO "$dmg"
hdiutil verify "$dmg"
shasum -a 256 "$dmg" > "$dmg.sha256"
