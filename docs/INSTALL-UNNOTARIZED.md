# Install ByteBloom v0.1.1 from the unnotarized DMG

These instructions describe a candidate pending publication. GitHub’s source
ZIP and tar.gz contain the project source. The separate DMG contains the app
and an Applications shortcut.

The app uses an ad-hoc signature. Apple has neither verified the developer’s
identity through Developer ID nor notarized this app. The published SHA-256
checksum can detect an archive mismatch. It cannot authenticate the publisher
or substitute for Developer ID signing.

1. Once published, download `ByteBloom-0.1.1-macOS-UNNOTARIZED.dmg` from the
   official ByteBloom GitHub release and compare its SHA-256 with the listed
   checksum.
2. Open the DMG, drag **ByteBloom.app** onto **Applications**, and eject the
   disk image.
3. Open **ByteBloom** from Applications. Expect a macOS warning that the
   developer cannot be verified or Apple cannot check the app. Dismiss the
   warning.
4. If you trust the source and have verified the download, open **System
   Settings → Privacy & Security**. Under **Security**, select **Open Anyway**
   for ByteBloom. Authenticate if prompted and confirm in the dialog. macOS
   may remember the exception for subsequent launches. Follow
   [Apple’s official guidance](https://support.apple.com/en-us/102445).
5. If **Open Anyway** is unavailable or fails, use the
   [build-from-source instructions](https://github.com/juswilvel/ByteBloom#build-from-source).
   Keep macOS security settings enabled.

The binary contains arm64 and x86_64 slices and targets macOS 14.0. Runtime
compatibility on macOS 14 and Intel hardware has not been independently
verified. External file providers and removable volumes have not been tested
comprehensively. No accessibility certification is claimed.
