# ByteBloom: Instructions for Coding Agents

## Authority

The project owner has final decision-making authority.

docs/MVP.md is the binding release specification.
docs/DECISIONS.md records significant decisions.
README.md documents the public project and build procedure.

Chat discussions and model suggestions do not override
the repository's approved specification.

Do not begin feature implementation until separately authorized.

## Primary agent

Codex is the primary local implementation agent.

Other AI tools may review specific questions but must not make
competing changes to the same working tree.

## Scope

Build one native macOS application using Swift, SwiftUI,
CryptoKit, Core Graphics, ImageIO, and Apple frameworks.

Preserve the five boundaries described in docs/MVP.md.

Do not introduce packages, services, APIs, analytics, network
entitlements, paid products, or unnecessary abstractions.

Do not add features listed as excluded in docs/MVP.md.

## Determinism

Use an explicit bloom-v1 algorithm identifier.

SHA-256, file size, byte histogram, and entropy are the
approved data sources for artwork parameters.

Use documented digest-byte ordering and fixed SplitMix64.

Never use timestamps, filenames, paths, Swift hashValue,
or nondeterministic random sources for artwork parameters.

Do not change a frozen algorithm mapping without approval
and appropriate versioning.

## Security and file access

Never alter a source file.

Never transmit file contents or create analytics/telemetry.

Use bounded-memory streaming and cancellable background work.

Acquire and release security-scoped access correctly.

Protect the imported file from accidental export overwrite.

Never commit real user files, credentials, secrets, build
artifacts, or environment-specific configuration.

Do not inspect unrelated personal directories or repositories.

## Implementation discipline

- Read the MVP specification before changing code.
- Make the smallest changes needed for the current milestone.
- Preserve working code unless a change has a clear reason.
- Use native APIs and readable Swift.
- Keep implementation testable.
- Build after significant changes.
- Run relevant tests and disclose failures.
- Keep Git commits focused and meaningful.
- Record material architecture decisions.
- Report completed work, verification, and remaining risks.

Do not claim tests pass unless they were executed.

Visual quality must be reviewed against the approved
six-sample gallery.

## Git and release

Canonical root: ~/Projects/ByteBloom
Canonical remote: juswilvel/ByteBloom
Main branch: main
License: MIT

Repository creation, visibility changes, destructive actions,
force-pushes, and public releases require explicit approval.

Do not change another repository or global Git configuration.

## Communication

The project owner should not need to hand-write application code.

Use meaningful milestone checkpoints, not permission requests
for trivial internal implementation choices.

For Terminal commands requiring output review, include automatic
macOS clipboard capture through pbcopy and display the report.

Report material deviations for approval before proceeding.
