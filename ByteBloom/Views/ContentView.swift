import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("ByteBloom")
                .font(.largeTitle.bold())

            Text("Every file has a hidden beauty.")
                .foregroundStyle(.secondary)

            Text("Project foundation only.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 600, minHeight: 440)
    }
}
