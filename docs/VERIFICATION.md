# v0.1.0 release-candidate verification

Status: private release candidate, pending owner evaluation. No release,
publication, merge to main, or visibility change is authorized.

## Baseline and frozen artwork

Owner-accepted artwork and `bloom-v1` parameter mapping: `aa373d1`.
The generator and renderer source files are unchanged from that commit.
The app preview and export use those same production components.

## Executed automated checks

- Xcode Debug build and tests with signing disabled: 23 tests passed during
  integration (before the additional unreadable-file check).
- Final Xcode Debug build **with ad-hoc signing and App Sandbox enabled**:
  build succeeded; **24 tests passed, zero failures**.
- Fresh private GitHub checkout at `7d601ac`, with separate derived data:
  signed Release build succeeded. The final documentation commit changes
  no application or test code.
- Signature verification passed. The signed app has sandbox and user-selected
  read/write entitlements; Debug also has `get-task-allow`. No network entitlement.
- SHA-256, histogram, entropy, chunk boundaries, eligibility, read-only handling,
  cancellation, best-effort changes, golden mapping, rendering, PNG encoding,
  and preview/export normalized composition remain covered.
- New integration checks cover missing/unreadable inputs, active replacement
  during a 512 MiB read, canceled/failed result preservation, PNG writing,
  hard-link/symlink/Finder-alias source protection, and destination-change races.
- Source scan found no application networking or telemetry code.

The existing Xcode headermap and AppIntents metadata warnings remain. The
hosted tests also emit a system autoShortcut service diagnostic. These do not
fail the build/tests. No concurrency warnings are suppressed.

## Exercised in the running signed, sandboxed app

Only generated synthetic files were used.

| Interaction | Observed result |
|---|---|
| Welcome screen | Labeled demonstration bloom, drop instructions, native picker action |
| Native file picker | Imported 131,072-byte ASCII fixture successfully |
| Explore the Bytes | Exact count, entropy 3.9886, 16 grouped frequencies, abbreviated digest |
| Full fingerprint copy | All 64 expected hex characters pasted into a native Finder field |
| Native save dialog | Default ByteBloom.png; successful PNG save |
| Actual saved PNG | 2048 × 2048, opaque RGB, sRGB, no source metadata |
| Approved composition | Decoded exported pixels exactly matched the approved 2048 gallery image on this OS |
| Empty and oversized files | Informative errors; previous successful bloom retained |
| Symbolic-link input | Rejected; previous bloom retained |
| Maximum-size input | 512 MiB file completed successfully with correct count and zero entropy |
| Source overwrite attempt | Imported the PNG, selected the same export path, confirmed native Replace; application blocked it |
| Native save cancellation | Returned to the previous result with controls available |
| Attached native sheets | Final import/save sheet focus, successful export, and cancel rechecked after the panel attachment fix |
| Source integrity | Synthetic input checksums unchanged after these interactions |

## Owner checks still required

- **Finder drag-and-drop** is implemented through SwiftUI's native URL drop
  destination, but a cross-window drag was not successfully exercised by the
  computer-control interface. Verify one file, multiple files, and a directory.
- **Manual in-flight cancellation and rapid replacement**: automated tests pass.
  The 512 MiB UI import completed before the control tool could click Cancel;
  do not interpret this as a manual cancellation pass.
- Exercise permission-denied recovery, Finder aliases, nonlocal/cloud-provider
  files, and removable volumes in representative real use. Unit tests cover
  unreadable files and aliases; provider-specific UI behavior remains unverified.
- Evaluate keyboard/VoiceOver behavior, small-window layout, and overall product
  polish. Check the minimum supported macOS version on actual macOS 14 hardware/VM.
- Final owner release-candidate acceptance, and any later publication, are separate.

## Reproducible owner walkthrough

1. Build/run the ByteBloom scheme in Xcode. Use a small, non-sensitive local file.
2. Select it with ⌘O, open Explore the Bytes, and copy/compare its full SHA-256.
3. Drag a second file from Finder; try two files and a folder to inspect recovery.
4. Try an empty file and a file over 512 MiB. The successful result should remain.
5. On a sufficiently slow input, cancel or replace the active import.
6. Export with ⇧⌘S; inspect the PNG. Try exporting to the imported source path
   using a disposable synthetic source. ByteBloom should refuse the overwrite.
7. Cancel a save dialog and retry. Close/reopen the window and confirm there is
   no persistent history of imported files.

See README for build/test commands. Review artifacts and synthetic fixtures
are kept outside the tracked repository; binaries and sample files are not committed.
