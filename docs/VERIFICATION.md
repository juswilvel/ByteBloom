# v0.1.0 release-candidate verification

Status: private release candidate. The owner provisionally accepted core
functionality; final layout/accessibility acceptance remains pending. No release,
publication, merge to main, or visibility change is authorized.

## Baseline and frozen artwork

Owner-accepted artwork and `bloom-v1` parameter mapping: `aa373d1`.
The generator and renderer source files are unchanged from that commit.
The app preview and export use those same production components.

## Original integration checks (November 14, 2026)

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

## Layout and accessibility hardening (November 15, 2026)

The owner reports successful manual testing of Finder drag-and-drop, picker,
byte exploration/copying, export, picker/save cancellation, error recovery,
and in-flight cancellation/replacement. These are owner-reported passes for
the preceding candidate, not newly automated UI passes.

Only `ContentView.swift` changes application behavior in this refinement.
The header, notice, and cancellation controls stay above one vertical scroll
area. Artwork keeps its square aspect ratio and a bounded viewport-relative
size; expanded details scroll rather than squeezing it. Statistics use
`ViewThatFits` to move the fingerprint below size/entropy, then stack the
remaining metrics if needed. Native text styles replace small fixed text.
The configured 820 × 720 minimum content size is unchanged.

Artwork now uses a labeled `Image` initializer, not `Image(decorative:)`.
The disclosure exposes Expanded/Collapsed, Copy and Dismiss have names,
metrics expose labels and values, and all 16 histogram groups (including
zero counts) have separate accessibility elements. AppKit announcements
request feedback for errors, cancellation, copying, saves, and completed
imports. No accessibility package or additional framework was introduced.

### Executed layout matrix

Actual running, ad-hoc signed, sandbox-enabled application windows were
examined using only synthetic inputs. Each size was checked in welcome and
result states, with a notice, and with details collapsed and expanded.
Screenshots of expanded content include the scrolled position; the artwork
above the viewport is naturally scrolled out, not distorted or clipped by
its image container. Header controls remain visible.

| Requested size | Observed outer window (points) | Usable content (points) |
|---|---|---|
| Minimum 820 × 720 | 820 × 752 | 820 × 720 |
| Default 1000 × 850 | 1000 × 850 | 1000 × 818 |
| Large 1280 × 900 | 1280 × 900 | 1280 × 868 |

The 32-point title bar explains the difference. Captures are at 2× Retina
resolution. Window restoration interfered with exact sizing, so temporary
copies outside the repository used isolated bundle identifiers and only
changed the initial window size. They run the same application views,
model, analyzer, renderer, file access, and sandbox entitlements. No test
launch configuration is committed. The canonical build was also launched
and its final accessibility tree, import, and export checked directly.

A separate temporary minimum-size stress build increased presentation text
to 17–24 points (roughly 150%) without changing layout geometry. Its
statistics successfully moved to two rows, and explanatory text wrapped.
This is a layout stress test, not evidence of automatic macOS reading-size
support: System Settings lists supported apps, and ByteBloom is not listed.

### Accessibility and regression checklist

| Check | Evidence / outcome |
|---|---|
| Full Keyboard Access | Enabled in System Settings for testing; original off state restored |
| Tab order | Choose Another File → Export → Dismiss when present → Explore → Copy; reverse navigation exercised |
| Space activation | Welcome picker, Export, Explore, Copy, and Dismiss exercised successfully |
| Native dialogs | Keyboard-only path entry/import and PNG save; Escape canceled save successfully |
| Focus indicators | Focus targets verified through accessibility state; the system focus overlay is not captured reliably by the app-only screenshot tool, so visual confirmation remains manual |
| Artwork semantics | Image role and botanical/demo description present in the final accessibility tree |
| Disclosure and copy | Expanded/Collapsed value and full-fingerprint action name inspected |
| Statistics/histogram | Exact metric values and 16 individually labeled count elements inspected, including zero bins |
| Error/completion feedback | Visible and accessible text verified; native announcement requests implemented |
| VoiceOver | Enable/disable attempted through System Settings; the control interface could not verify an active spoken/caption session. Spoken output and announcement timing are **not marked passed**. Original off state restored |
| Enlarged text | Temporary font stress build passed at minimum width; not a global text-size support claim |
| Import/error/export | Synthetic imports, empty-file recovery, full fingerprint copy, native PNG export, and save cancellation rechecked |
| Finder drag regression | Two cross-window attempts through the control interface did not complete. Owner's preceding manual pass is retained; this refinement needs a brief owner recheck |

Final signed Debug build/test: **24 tests, zero failures**. Existing analyzer,
generator, renderer, file-access, cancellation, replacement, and export tests
are retained. No new state behavior was introduced that requires a separate
unit test; native layout/accessibility checks supplement the existing suite.
Xcode injects temporary filesystem and testmanager permissions into its test
host. A separate standalone build (without tests) was signature-verified and
used for native import/export checks; its entitlements contain only sandbox,
user-selected read/write, and Debug get-task-allow. The isolated size-check
builds also use these normal entitlements. No new
networking, telemetry, entitlements, dependencies, or project-format changes.

The final UI-exported PNG is 2048 × 2048, opaque sRGB, and byte-for-byte
identical to the previously accepted export for the same synthetic input:
`16cf672a81c787598e3ef13ec7c088dc9ccf54dcd0709ec9f54e70494496c2b9`.
Generator and renderer remain byte-for-byte unchanged from `aa373d1`.

## Owner checks still required

- Listen with VoiceOver to the artwork description, disclosure state, all
  histogram groups, and error/save/copy announcements; inspect focus visibility.
- Briefly recheck Finder drag-and-drop after the scrolling/layout change.
- Evaluate final product polish and representative keyboard use. A complete
  assistive-technology usability audit is not claimed.
- Provider/removable-volume behavior and actual macOS 14 runtime compatibility
  remain unverified; the deployment target alone does not prove compatibility.
- Final owner release acceptance and publication remain separate approvals.

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
