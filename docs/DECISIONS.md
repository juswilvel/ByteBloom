# ByteBloom: Decision Log

Authority: Foundational Project Blueprint v1.0.
Approved: November 14, 2026.

| ID | Decision | Status |
|---|---|---|
| D-001 | Name ByteBloom; tagline "Every file has a hidden beauty." | Approved |
| D-002 | Native offline single-file macOS application | Approved |
| D-003 | Luminous Botanical Rosette with filaments | Approved |
| D-004 | SwiftUI, Core Graphics, CryptoKit | Approved |
| D-005 | Versioned deterministic bloom algorithm | Approved |
| D-006 | 512 MiB maximum file size | Approved |
| D-007 | Opaque 2048 x 2048 PNG export | Approved |
| D-008 | Public source-only first release | Approved |
| D-009 | Codex as sole primary implementation agent | Approved |
| D-010 | juswilvel/ByteBloom; MIT license | Approved |
| D-011 | Private GitHub repository before release | Approved |
| D-012 | macOS 14 minimum deployment target | Confirmed |
| D-013 | Built-in frameworks; no paid services or dependencies | Approved |
| D-014 | Prebuilt Mac app distribution postponed | Approved |
| D-015 | Native Xcode JSON project format | Bootstrapped |

## Verified development environment

- Apple silicon MacBook Pro.
- macOS 27.2.1.
- Xcode 27.2, build 27B52.
- Swift compiler 6.4.2.
- Swift language mode 6.
- macOS SDK 27.2.
- Minimum deployment target 14.0.
- GitHub account juswilvel.

## Architectural principles

Keep file access, binary analysis, parameter generation,
rendering, and presentation logically separate.

Freeze the exact bloom-v1 numerical mappings and seed
conventions after their initial tests are accepted.

Do not rewrite established functional components without
a demonstrated technical reason.

No third-party dependency, service, external API, cost,
or material scope change without owner approval.

## Current phase

The owner formally accepted the refined Luminous Botanical Rosette and
froze the `bloom-v1` parameter mapping at commit
`aa373d1790184ff8044b1278bbb7def085719cce`. Phases E–G (native UI,
import, export, verification, and release-candidate documentation) are
authorized. Changes to the frozen mapping require explicit approval and
appropriate algorithm versioning. Publication and release are not authorized.

The checkpoint entries below are historical; their pending approval gates
were satisfied by this acceptance.

The owner's implementation kickoff authorized Phases A–D on
November 14, 2026. Binary analysis, deterministic parameters, and
the Core Graphics renderer are implemented on the feature branch.
The six-sample gallery is generated; explicit owner visual acceptance
is pending. Full UI and export integration remain gated by that review.

### Implementation checkpoint: Phases A–D

- FileAccess owns eligibility checks, security scope, read-only handle
  lifetime, and a cancellable detached worker. BinaryAnalyzer owns
  one-pass chunked measurements and does not import graphics or UI.
- Candidate `bloom-v1` uses four big-endian UInt64 digest words XORed
  into a fixed SplitMix64 seed. Precise mappings and consumption order
  are documented in `BloomGeneratorV1.swift` and covered by golden tests.
- BloomRenderer draws only normalized geometry into an opaque sRGB
  bitmap, with one rendering implementation for previews and 2048-pixel
  artwork. No additional application or framework target was added.
- A temporary Swift harness outside the repository generated six safe
  fixtures, PNG previews, full-size PNGs, a labeled contact sheet, and
  measured/derived parameter summaries. Generated artifacts are untracked.
- Mapping stability and artistic acceptance are pending owner review;
  passing technical tests does not constitute visual approval.

### Phase D refinement 1: candidate mapping change

The owner accepted the initial technical review but withheld artistic
approval, authorizing one focused refinement of light, core, silhouette,
and filament visibility. The direction and single Core Graphics renderer
are retained. No UI, import, or export-dialog integration is authorized yet.

The still-candidate `bloom-v1` mapping intentionally changes petal length,
width, bend, taper, and layer angles. Digest bytes 4–8 now control fullness,
sweep, layer spacing, two-lobed elongation, and stagger. Histogram mean and
concentration additionally shape breadth, sweep, and taper. Exact bounded
formulas remain in `BloomGeneratorV1.swift`; independent golden references
and structural regression checks cover the change. The SHA-256 seed,
SplitMix64 consumption order, palette selection, principal petal count,
orientation, growth, filament parameters, and motes retain their mappings.

Directional surface gradients and selective rim light separate the three
layers. A compact golden-angle seed cluster and short stamens replace the
dark central aperture. Veins and existing filaments have greater contrast;
particle and filament counts are unchanged. Lighting uses two gradients
per petal, with shadow composited into the gradient stops. Expensive
per-petal radial glow was omitted.

The original six input byte sequences and gallery are preserved. A new
untracked review directory contains before/after comparisons, seven
1024-pixel previews and 2048-pixel PNGs (including Moonflower blue), full
parameter records, test results, and a same-machine rendering comparison.
Explicit owner visual acceptance remains pending.

Public visibility and v0.1.0 release require separate
explicit approval.

Future decisions should be recorded here only when
they materially affect the product or architecture.

### Phases E–G: native integration and private release candidate

- A single SwiftUI Window presents welcome/demo, analysis/rendering, result,
  recoverable notices, byte exploration, and export. Window-attached native open/save panels
  and a URL drop destination feed one main-actor state model.
- A generation counter prevents stale analysis/progress from replacing the
  current result. Streaming, parameter generation, rendering, and PNG writing
  run on cancellable detached workers. Only measured/derived results remain
  in memory; no persistent file history or source-data cache was added.
- FileAccess captures device/inode identity from the open read-only descriptor.
  It is used solely for export protection, never for artwork. Export rejects
  the source path/identity and alias/symlink destinations, revalidates the
  destination after rendering, and writes atomically under NSFileCoordinator.
- Cancellation is checked immediately before the atomic write. A write already
  committed reports success rather than claiming that an existing output was canceled.
- Project signing defaults to ad-hoc Sign to Run Locally with App Sandbox,
  without an environment-specific team identity. Version 0.1.0/build 1 is a
  private release candidate, not a public release or notarized distribution.
- docs/VERIFICATION.md separates actual signed-app interactions, automated
  checks, and outstanding owner acceptance items. The frozen generator and
  renderer remain byte-for-byte unchanged from aa373d1.

### Focused layout/accessibility hardening

The owner provisionally accepted core functionality and authorized a focused
presentation correction. The frozen `bloom-v1` mapping and renderer remain
unchanged. One scroll area provides overflow below fixed primary controls;
intrinsic-size adaptive statistics replace the fixed horizontal row. Native
text styles, labeled artwork, explicit metric/histogram accessibility values,
and AppKit feedback announcements improve semantics without changing file
access or processing state. The minimum content size remains 820 × 720.

The repository retains the Xcode 27+ JSON `.xcproj` format and macOS 14.0
deployment target. README distinguishes the build Mac/Xcode requirements
from unverified macOS 14 runtime compatibility. Final owner review, repository
visibility changes, merges, and publication remain separate gates.

### v0.1.1 owner-authorized improvement cycle

The owner authorized a native AppIcon, a one-click result explanation, version
0.1.1/build 2, installation investigation, and DMG preparation. This extends
the v0.1.0 source-only scope for review. The frozen bloom-v1 generator and
renderer remain the artwork contract. Public binary distribution and merging
this feature branch require separate approval.

The icon uses the approved Moonflower blue synthetic sample, framed and
downsampled with Core Graphics. Design/AppIcon-Master.png is its editable source.
The result explanation uses a native popover with scrollable native text.
No valid code-signing identities were found on the development Mac. Packaging
therefore produces an ad-hoc signed local QA DMG, without notarization.
