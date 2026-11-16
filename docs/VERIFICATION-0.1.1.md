# v0.1.1 release verification

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

## Signing availability and distribution decision

security find-identity reported zero valid code-signing identities. Developer ID
Application signing capability is therefore unavailable on this Mac. notarytool
is installed. Authentication was not exercised because the required signing
identity is missing. Enrollment status and stored notarization profiles remain
unverified. No credentials were created or changed and no notarization request
was submitted.

The original LOCAL-QA DMG used ad-hoc signing, and Gatekeeper rejected it.
Developer ID signing and Apple notarization remain unavailable. The owner
subsequently approved an explicitly labeled unnotarized DMG for the
[v0.1.1 release](https://github.com/juswilvel/ByteBloom/releases/tag/v0.1.1). Apple has neither verified the publisher’s
identity through Developer ID nor notarized the app. The manual Open Anyway
test for the distribution candidate is documented below.

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

## Remaining verification limits

- Visual icon checks in Dock, Spotlight, and Application Switcher. Dock tool
  inspection timed out.
- Keyboard focus/Space activation, spoken VoiceOver behavior, enlarged-text
  settings, and a fresh Finder drag-and-drop regression check.
- Intel execution, macOS 14 runtime, external providers and removable volumes.
- Accessibility certification is not claimed. The owner approved the icon
  and educational popover after independent candidate review.

Review files, DMG, checksum, screenshot, logs, and draft notes are outside the
repository. The earlier local QA artifacts are under /tmp/ByteBloom-0.1.1-review.
No binaries are committed.

## Unnotarized distribution candidate

The owner authorized a separately labeled unnotarized DMG for distribution
testing. `scripts/package-unnotarized.sh` packages the existing universal
Release build with an Applications shortcut and the
[installation guide](INSTALL-UNNOTARIZED.md). The original local QA package
remains separate.

The complete test suite rerun passed 24 tests, including the unchanged
deterministic golden tests. A fresh universal Release build succeeded.
The candidate disk image passed integrity verification. Its app has a valid
ad-hoc signature, Hardened Runtime, App Sandbox, and user-selected read/write
access. The binary contains arm64 and x86_64 and declares macOS 14.0.

On macOS 27.2.1 (Apple silicon), Gatekeeper blocked the first Finder launch
of a disposable installation from a simulated quarantined download. System
Settings offered **Open Anyway**. After the follow-up confirmation, macOS
required owner authentication. The owner completed it personally.

ByteBloom then showed its welcome window. The synthetic file imported through
the native picker and the app exported a 2048 × 2048 opaque sRGB PNG that
matched the accepted reference byte for byte. After quitting, the same
disposable app launched again from Finder without another warning or
authentication prompt. macOS kept its quarantine attribute and launched both
instances through App Translocation. Gatekeeper remained enabled and a
before/after file manifest confirmed the canonical installation was unchanged.

This validates the disclosed Open Anyway path on the tested host. macOS 14,
Intel hardware, and managed-device policies were not tested.

## Final guide repackaging

The final candidate embeds the publication-ready installation guide. Its
application bundle was compared file by file against the original tested DMG
and the disposable installation. All bundle file bytes matched, strict
signature verification passed, and the repackaged DMG passed integrity
verification. The original test result applies to the identical app bundle.
The release archive is `ByteBloom-0.1.1-macOS-UNNOTARIZED.dmg` (2,490,536
bytes). Its SHA-256 is
`45b61abede4be9953ef6eeeb17af3250804ba64c7f028f21e20bfdb15b4b7017`.

The full Xcode suite passed again for publication (24 tests, zero failures),
and a fresh universal Release build passed. The checked release DMG uses the
previously tested app bundle.
