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

Public visibility and v0.1.0 release require separate
explicit approval.

Future decisions should be recorded here only when
they materially affect the product or architecture.
