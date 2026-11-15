# ByteBloom

**Every file has a hidden beauty.**

ByteBloom is an open-source native macOS application that
transforms the binary contents of a file into deterministic,
luminous botanical artwork.

Drop a file, discover its bloom, explore the underlying byte
statistics, and export the result as a high-quality PNG.

## Project status

**Foundation bootstrapped. v0.1.0 is not implemented yet.**

The current Xcode project contains a minimal placeholder
application and a test target. File analysis, bloom rendering,
import interaction, and PNG export are upcoming features.

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
