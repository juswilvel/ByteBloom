import SwiftUI

struct BloomExplanation: View {
    let paletteName: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How this bloom works")
                .font(.title2).accessibilityAddTraits(.isHeader)
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("This flower grows from the actual contents of your file.")
                    Text("Palette: \(paletteName)").font(.headline)
                    Text("SHA-256 is a fingerprint of all the file’s bytes. It selects a curated palette and influences petal count, orientation, and fine variation. Colors come from that palette, rather than the visible colors of an image file.")
                    Text("File size sets growth within a fixed range. How often each byte value appears shapes contours and veins.")
                    Text("Shannon entropy measures how evenly byte values are distributed. It influences filament density and texture.")
                    Text("Identical contents produce the same bloom-v1 parameters. Different files can look similar, and rendered pixels can vary between macOS versions. These measurements do not certify security.")
                        .foregroundStyle(.secondary)
                }
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            Button("Done") { dismiss() }
                .keyboardShortcut(.cancelAction)
        }
        .padding(24)
        .frame(width: 380, height: 480)
        .onExitCommand { dismiss() }
    }
}
