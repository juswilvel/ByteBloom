# ByteBloom

**Every file has a hidden beauty.**

ByteBloom v0.1.0 is a native macOS application that turns a file's complete binary
contents into deterministic, luminous botanical artwork. All processing
happens locally with Apple frameworks and no third-party dependencies.

## How it works

**Is it random?** No. ByteBloom reads the file's bytes and uses measurements of
those bytes to set the artwork parameters. Identical contents produce identical
`bloom-v1` parameters under the same algorithm version, even if the files have
different names.

**Why do blooms look different?** Four properties influence the artwork:

| File property | What it influences |
| --- | --- |
| SHA-256 fingerprint, a digest calculated from the whole file | Palette, orientation, petal count, and fine variations |
| File size | How large the bloom grows within a fixed range |
| Byte frequencies, or how often each byte value occurs | Petal contours and veins |
| Shannon entropy, a measure of how evenly byte values are distributed | Filament density and texture |

**How are colors chosen?** The fingerprint selects one of four curated
palettes. Even for an image file, ByteBloom works from the encoded bytes
without sampling visible colors. The app draws blooms locally without an AI
image-generation service.

Different files can produce similar-looking blooms, and PNG bytes may vary
across macOS versions.

## Use ByteBloom

1. Launch the app. The welcome artwork is explicitly labeled as a synthetic
   demonstration, not an analyzed user file.
2. Choose a file with **Choose a File…** (`⌘O`), or drag one file from Finder
   into the window. Files must be locally available regular files from
   1 byte through 512 MiB. Folders, apps, aliases, and symlinks are rejected.
3. Watch analysis progress or cancel. Selecting another file cancels prior
   analysis. Failed or canceled imports preserve the previous successful bloom.
4. Open **Explore the Bytes** for exact size, Shannon entropy, a 16-bin byte
   histogram, and the SHA-256 fingerprint. Details scroll when space is tight;
   statistics adapt to the available width. The copy button copies all 64 hex
   characters. With Full Keyboard Access enabled, use Tab/Shift-Tab to move
   among controls and Space to activate them.
5. Choose **Export PNG…** (`⇧⌘S`). The native save dialog defaults to
   `ByteBloom.png`. Output is an opaque, sRGB, 2048 × 2048 PNG using the same
   normalized composition as the preview. Existing unrelated files require
   the save panel's replacement confirmation. The source file is protected,
   including matching hard-link identity; alias/symlink destinations are rejected.

An export canceled before writing leaves the destination unchanged. If its
atomic save has already begun, a completed save reports success. Save errors
are recoverable and the bloom remains available for another attempt.

## Build and run

The configured application deployment target is **macOS 14.0**. Runtime
compatibility on macOS 14 has not yet been independently verified.

The current JSON `project.xcproj` format requires **Xcode 27 or later**.
**Xcode 27.2 requires macOS 26.6 or later on the build Mac**; this build-host
requirement is separate from the application deployment target. Development
is verified with Xcode 27.2 / Swift compiler 6.4.2 on macOS 27.2.1, using Swift 6.
There are no package installation or service setup steps.

Clone the source from the `main` branch:

```sh
git clone --branch main https://github.com/juswilvel/ByteBloom.git
cd ByteBloom
```

Open `ByteBloom.xcodeproj`, select the **ByteBloom** scheme and **My Mac**,
then press **Run** (`⌘R`). The project uses **Sign to Run Locally** (ad-hoc
signing), so an Apple Developer account is not required for local evaluation.
App Sandbox and user-selected read/write access remain enabled.

Alternatively, build and launch from Terminal:

```sh
xcodebuild -project ByteBloom.xcodeproj -scheme ByteBloom \
  -configuration Debug -destination 'platform=macOS' \
  -derivedDataPath /tmp/ByteBloom-build build
open /tmp/ByteBloom-build/Build/Products/Debug/ByteBloom.app
```

Build ByteBloom from source. Prebuilt and notarized application
binaries are not included.

## Tests and review

```sh
xcodebuild -project ByteBloom.xcodeproj -scheme ByteBloom \
  -configuration Debug -destination 'platform=macOS' \
  -derivedDataPath /tmp/ByteBloom-build build test
```

The 24 tests cover streaming SHA-256 and entropy reference values, histograms,
chunk boundaries, cancellation, file eligibility and change detection,
frozen mapping goldens, deterministic rendering, opaque sRGB PNG output,
preview/export composition, active import replacement, result preservation,
and source protection across hard links, symlinks, and Finder aliases.
Tests create only synthetic temporary files, including sparse size-limit fixtures.

See [v0.1.0 verification](docs/VERIFICATION.md) for executed UI
checks, owner-reported manual results, and remaining limitations. macOS 14
compatibility has not been independently verified.

## Privacy and interpretation

- Source files are opened read-only and streamed in approximately 1 MiB chunks.
  Raw source contents are not retained in the result or persisted.
- Security-scoped access is balanced around file operations. No bookmarks,
  file history, telemetry, analytics, or network entitlements are used.
- Exported artwork contains no source filename, path, or fingerprint metadata.
- Byte entropy measures byte-value distribution. It does not establish
  randomness, compression, encryption, malware status, or security.
- Equal bytes yield equal `bloom-v1` parameters. Visually unique artwork is
  not guaranteed, nor is pixel-identical rendering/PNG encoding across OS versions.
- Change detection during reading is best effort, not an atomic filesystem
  snapshot. ByteBloom does not initiate cloud downloads; OS file-provider
  synchronization is outside its offline-processing guarantee.

## Design and license

- [MVP specification](docs/MVP.md)
- [Architecture decisions and algorithm freeze](docs/DECISIONS.md)
- [Coding-agent instructions](AGENTS.md)

MIT. See [LICENSE](LICENSE).
