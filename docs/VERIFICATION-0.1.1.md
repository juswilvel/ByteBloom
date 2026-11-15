# v0.1.1 owner review

## Implemented

Version 0.1.1/build 2 adds the approved Moonflower blue bloom as a native macOS
AppIcon and a result-screen explanation popover. The editable master and native
generation script live in Design. The master derives from the synthetic phrase
“Moonflower synthetic palette sample 6.\n” repeated 512 times, rendered by the
accepted bloom-v1 implementation. Icon framing does not alter the renderer.

The explanation opens directly from the result, names its palette, and covers
fingerprint, size, frequencies, entropy, and deterministic limitations. It uses
native text styles and a scrollable body with a persistent Done button.

## Executed verification

- Complete Debug Xcode suite passed, 24 tests with zero failures.
- The first attempt failed before tests loaded because ad-hoc XCTest bundles
  could not load into a hardened host. Hardened Runtime is now Release-only.
- Universal Release build passed. Binary contains x86_64 and arm64.
- Signature verification passed with an ad-hoc signature and Hardened Runtime.
- Final Release entitlements contain exactly App Sandbox and user-selected
  read/write. Xcode base-entitlement injection is disabled for Release, removing
  get-task-allow. The final DMG app was installed and launched again, with import
  and popover open/Escape checks repeated successfully.
- Installed bundle reports 0.1.1 (2), macOS 14 minimum, and AppIcon metadata.
- Native AppIcon asset variants and a 16/32/64/128/512 review sheet generated.
- Finder visibly displayed the installed icon.
- Installed app launched, imported the synthetic 131,072-byte sample, opened
  the popover in one click, and dismissed it with Escape.
- Accessibility tree exposes the explanation button, heading, full content,
  selected palette, and Done button.
- Popover displayed without clipping in the restored minimum-width window.
- Native save dialog exported an opaque PNG whose SHA-256 exactly matches the
  accepted v0.1.0 sample export:
  16cf672a81c787598e3ef13ec7c088dc9ccf54dcd0709ec9f54e70494496c2b9.
- Frozen generator and renderer source match aa373d1.
- DMG integrity verified, mounted, and its app copied to ~/Applications.
- Existing v0.1.0 tag and release remain preserved.

## Distribution blocker

security find-identity reported zero valid code-signing identities. Developer ID
Application signing capability is therefore unavailable on this Mac. notarytool
is installed. Authentication was not exercised because the required signing
identity is missing. Enrollment status and stored notarization profiles remain
unverified. No credentials were created or changed and no notarization request
was submitted.

The DMG is explicitly marked LOCAL-QA, signed ad-hoc, and not notarized.
Gatekeeper assessment rejects it. It must not be presented as a trusted public
installer. To proceed with public binary distribution, the owner needs a valid
Developer ID Application certificate/private key and existing authorized
notarization authentication.

## Installation and duplicate inventory

Spotlight found two existing 0.1.0 bundles, both with identifier
com.juswilvel.ByteBloom:

- ~/Applications/ByteBloom.app — canonical routine-launch installation.
- ~/Library/Developer/Xcode/DerivedData/ByteBloom-LocalInstall/Build/Products/Release/ByteBloom.app
  — Xcode build output.

Both have the display name ByteBloom, so Spotlight distinguishes them by
location. The old missing icon made them harder to distinguish. Debug/Release
builds in temporary review directories also exist and should be treated as
development copies. No index clearing or DerivedData deletion was performed.

The existing installation was validated and preserved as both a recovery ZIP
and a moved bundle under /tmp/ByteBloom-0.1.1-review before installing the DMG
copy into ~/Applications/ByteBloom.app. A durable recovery ZIP also lives at ~/Applications/ByteBloom Recovery/ByteBloom-0.1.0.zip.

## Remaining owner verification

- Visual icon checks in Dock, Spotlight, and Application Switcher. Dock tool
  inspection timed out.
- Keyboard focus/Space activation, spoken VoiceOver behavior, enlarged-text
  settings, and a fresh Finder drag-and-drop regression check.
- Intel execution, macOS 14 runtime, external providers and removable volumes.
- Final icon and UI acceptance. Accessibility certification is not claimed.

Review files, DMG, checksum, screenshot, logs, and draft notes are outside the
repository under /tmp/ByteBloom-0.1.1-review. The final package is in its final subdirectory.
No binaries are committed.
