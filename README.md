# ByteBloom

**Every file has a hidden beauty.**

ByteBloom is an open-source native macOS application that
transforms the binary contents of a file into deterministic,
luminous botanical artwork.

Drop a file, discover its bloom, explore the underlying byte
statistics, and export the result as a high-quality PNG.

## Project status

**Core pipeline implemented. Refined artwork review pending.**

The application still presents the foundation placeholder. The
streaming analyzer, read-only file-access boundary, deterministic
`bloom-v1` parameter generator, and native Core Graphics renderer
are implemented and tested. Preview and 2048-pixel rendering use
the same normalized geometry.

The six-sample gallery must receive explicit owner approval before
the full SwiftUI import workflow and native PNG export integration
proceed. This is not a completed v0.1.0 application or public release.

The first focused artwork refinement adds directional lighting, a luminous
seed core, clearer filaments, and bounded content-derived shape variation.
The candidate mapping changes are documented in the decision log; the
original gallery remains available for comparison during owner review.

The initial public release will provide source code and
documented build instructions. A prebuilt Mac app is deferred.

## Planned features

- Native, lightweight macOS interface.
- Drag-and-drop and native file selection.
- Local SHA-256, histogram, and entropy analysis.
- Deterministic content-derived botanical artwork.
- Compact educational byte statistics.
- 2048 x 2048 PNG export.
- Offline processing with no analytics or telemetry.

## Requirements

- Mac running macOS 14.0 or newer for the deployment target.
- Compatible full Xcode installation for building.
- Development environment verified with Xcode 27.2.

## Build from source

Clone:

    git clone https://github.com/juswilvel/ByteBloom.git
    cd ByteBloom

Open `ByteBloom.xcodeproj` in Xcode, select the ByteBloom
scheme, and build the macOS application.

Or verify compilation from Terminal:

    xcodebuild \
      -project ByteBloom.xcodeproj \
      -scheme ByteBloom \
      -configuration Debug \
      -destination 'generic/platform=macOS' \
      CODE_SIGNING_ALLOWED=NO \
      build

The command above verifies compilation without code signing.
Running the sandboxed application may require appropriate
development signing configuration.

Run the core tests on macOS:

    xcodebuild \
      -project ByteBloom.xcodeproj \
      -scheme ByteBloom \
      -configuration Debug \
      -destination 'platform=macOS' \
      CODE_SIGNING_ALLOWED=NO \
      test

Tests cover SHA-256 reference vectors, byte counts and entropy,
chunk-boundary consistency, cancellation, file eligibility and
change detection, SplitMix64 and numerical mapping golden values,
render repeatability, PNG color/opacity, and normalized composition.
Tests use generated synthetic data, never personal source files.

`BloomGeneratorV1.swift` documents numerical mappings, digest byte
ordering, seed derivation, and PRNG consumption. The candidate v1
mapping is regression-tested but awaits the visual acceptance gate
before being declared stable. Rasterized pixels and PNG encoding
are not guaranteed identical across operating-system versions.

## Design and documentation

- [MVP specification](docs/MVP.md)
- [Architecture decisions](docs/DECISIONS.md)
- [Coding-agent instructions](AGENTS.md)

## Privacy

ByteBloom is designed to process selected files locally,
without uploading their contents or collecting analytics.

It does not modify imported source files.

Deterministic blooms are not security certificates or
proof that two different files cannot yield similar artwork.

## License

MIT. See [LICENSE](LICENSE).
