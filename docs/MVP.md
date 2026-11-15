# ByteBloom v0.1.0: MVP Specification

Status: Approved, November 14, 2026.
Authority: Foundational Project Blueprint v1.0.
Implementation: Requires separate owner authorization.

## Product

ByteBloom is a native macOS application that transforms the
binary contents of a file into deterministic botanical artwork.

Tagline: Every file has a hidden beauty.

Art comes first. Binary discovery complements the artwork.

The initial release is an open-source Xcode project, not a
prebuilt or notarized application.

## Primary workflow

1. Launch a polished single-window macOS application.
2. Drag and drop one file or choose it using the native picker.
3. Analyze its complete contents locally and read-only.
4. Generate a deterministic luminous botanical bloom.
5. Explore meaningful binary measurements.
6. Export a high-resolution PNG.

## Input contract

- Exactly one file per import.
- Accept readable regular files regardless of extension.
- Minimum accepted size: 1 byte.
- Maximum accepted size: 536870912 bytes (512 MiB).
- Reject directories and application bundles.
- Reject symbolic links and Finder aliases in v0.1.0.
- Empty files receive an informative message, not a bloom.
- Reject unavailable, unreadable, or oversized inputs safely.
- No application-initiated cloud download.
- No file-format parsing required.
- Never modify the imported source file.

Keep the previous successful bloom when a new import fails,
is canceled, or is unavailable.

Cancel previous analysis when another import begins. Stale
asynchronous results must never replace the current result.

Detect changes during reading on a best-effort basis. Do not
claim to provide an atomic filesystem snapshot.

## Binary analysis

Process the entire accepted file in bounded-memory chunks,
approximately 1 MiB per read.

Calculate in one pass:

- Exact byte count.
- Full SHA-256 digest using CryptoKit.
- Histogram of all 256 byte values.
- Whole-file Shannon entropy, in bits per byte.

Entropy is computed from normalized histogram frequencies:
H = -sum(p[i] * log2(p[i])) for p[i] > 0.

Analysis and expensive rendering must run off the main UI
thread. Check cancellation between chunks, throttle progress
updates, and release file resources on every exit path.

Do not retain or persist raw source contents.

## Bloom Algorithm v1

Algorithm identifier: bloom-v1.

The visual design is a Luminous Botanical Rosette with
controlled filament details, not a conventional data chart.

Core characteristics:

- Three overlapping layers of curved botanical petals.
- 8 to 16 petals per principal layer.
- Four curated palettes.
- 32 to 128 primary filaments, entropy-dependent.
- Internal veins, a luminous center, subtle particles.
- Restrained glow and intentional dark negative space.

Use these content-derived influences:

- SHA-256: palette, orientation, petal count, fine variation.
- File size: bounded relative growth and scale.
- Entropy: filament density and texture.
- Byte histogram: contours and internal vein patterns.

The analyzer must be separate from the parameter generator.
The generator must be separate from the Core Graphics renderer.

Parameter generation must not depend on file name, file path,
timestamps, process-dependent hashValue, or system randomness.

Derive pseudorandom variation using a fixed SplitMix64
implementation and documented digest-byte ordering.

Freeze precise mappings and seed conventions in the first
tested implementation before declaring bloom-v1 stable.

Identical bytes must generate identical analysis and artwork
parameters under the same algorithm version.

Do not promise visibly unique designs, reversible file
identification, security certification, or pixel-identical PNG
encoding across graphics or OS versions.

Changing the established content-to-art mapping requires a
new algorithm version.

## Visual quality

Artwork must have a recognizable botanical identity, coherent
composition, good contrast, meaningful variation, and detail
that works at both thumbnail and full export resolution.

Evaluate at least six safe sample inputs:

1. Repeated zero bytes.
2. Repetitive ASCII text.
3. A complete, uniform 256-byte-value distribution.
4. Deterministic pseudorandom bytes.
5. Redistribution-safe image data.
6. Redistribution-safe firmware-like binary data.

No proprietary or personal samples may be committed.

Visual quality is an acceptance gate, not a bonus feature.

## Explore the Bytes

Present a compact disclosure section containing:

- File size, with exact bytes available.
- Byte entropy, 0 to 8 bits per byte.
- A 16-bin byte-frequency chart; each bin aggregates
  16 consecutive byte values.
- Abbreviated SHA-256 with full fingerprint copy action.

Explain that entropy measures byte-value distribution, not
malware, encryption, randomness, compressibility, or security.

## PNG export

- Exactly 2048 by 2048 pixels.
- Opaque, dark composition.
- sRGB color space.
- Native save dialog.
- Default output name: ByteBloom.png.
- Same normalized geometry and palette as preview.
- No embedded source path, filename, or fingerprint metadata.
- Do not allow overwriting the imported source file.
- An existing unrelated output requires user-approved replacement.
- Export errors and cancellation must be recoverable.

## Platform and security

- Native Swift and SwiftUI.
- Foundation, CryptoKit, Core Graphics, ImageIO,
  UniformTypeIdentifiers, and necessary AppKit APIs.
- Minimum deployment target: macOS 14.0.
- Swift language mode: Swift 6.
- Xcode 27.2 verified on development Mac.
- No third-party dependencies.
- App Sandbox enabled.
- User-selected file read/write entitlement for import/export.
- Open imported sources read-only despite entitlement scope.
- Balance security-scoped access correctly.
- No network entitlement, telemetry, or analytics.
- No broad home-directory or Documents/Downloads permissions.
- No persistent file history or source-data cache.

Operating-system file-provider synchronization is outside
ByteBloom's own offline-processing guarantee.

## Application behavior

States: Welcome, Analyzing, Ready, Error, Exporting.

- Keep UI responsive while analyzing or exporting.
- Support progress feedback and cancellation.
- Preserve the previous successful result on failure.
- Disable export until an artwork result is ready.
- Use one primary window without complex navigation.
- Keep all technical detail secondary to the bloom.

A fixed, in-memory demonstration input may supply welcome art,
but must never be represented as a user-analyzed file.

## Architecture

Five logical responsibilities:

1. FileAccess
2. BinaryAnalyzer
3. BloomGeneratorV1
4. BloomRenderer
5. SwiftUI presentation

Use one application target and one test target.

Avoid framework proliferation, databases, service layers, and
speculative cross-platform architecture.

## Definition of done

Binary correctness:

- SHA-256 matches known reference vectors.
- Histogram totals equal exact analyzed byte counts.
- One-byte and repeated-value entropy equals zero.
- Uniform 256-value entropy equals eight bits/byte.
- Repeated analyses yield identical bloom parameters.
- Different names with identical contents yield identical
  analysis and bloom parameters.
- Distinct fixtures have correct fingerprints and predictable
  deterministic derived parameters.

Application:

- Picker and drag-and-drop both work.
- Invalid, empty, inaccessible, oversized, and directory
  selections are handled without crashes.
- Cancellation and rapid replacement do not cause stale UI.
- File processing does not block normal UI interaction.
- No source file is modified.

Artwork and export:

- Six-sample visual gallery passes owner review.
- Art follows the approved botanical direction.
- Variation is not exclusively a palette difference.
- PNG is valid, opaque, sRGB, and exactly 2048 x 2048.
- Export matches preview composition.
- No prohibited source metadata is embedded.

Release:

- Build and run in Xcode on the development Mac.
- Core automated tests pass.
- Documentation and MIT license are present.
- Fresh checkout builds with documented instructions.
- No secrets, private inputs, or build outputs committed.
- No application network functionality.
- Owner explicitly approves public release.

## Exclusions

No iOS, batch processing, folders, file comparison, video,
animation export, cloud sync, accounts, galleries, commercial
features, App Store distribution, automatic updates, or
multiple sophisticated rendering engines.

## Schedule

Target approximately five implementation hours:

- Bootstrap: 25 min.
- Binary analysis: 45 min.
- Artwork: 90 min.
- Interface: 45 min.
- PNG export: 35 min.
- Hardening: 40 min.
- Documentation and final preparation: 20 min.

These are targets, not permission to waive acceptance criteria.

Cut nonessential animation, optional visualizations, cosmetic
controls, and noncritical UI polish first.

Never silently cut reliable import, determinism, attractive
artwork, safe export, or essential verification.

Material changes to this specification require owner approval.
