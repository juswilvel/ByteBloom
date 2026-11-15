import SwiftUI
import AppKit

struct ContentView: View {
    @Bindable var model: BloomModel
    @State private var targeted = false
    @State private var exploring = false
    private let accent = Color(red: 0.67, green: 0.84, blue: 0.77)
    private let background = Color(red: 0.026, green: 0.043, blue: 0.060)

    var body: some View {
        VStack(spacing: 0) {
            header
            if let message = model.message { notice(message) }
            if model.isBusy { progress }
            GeometryReader { viewport in
                ScrollView {
                    VStack(spacing: 20) {
                        if let result = model.result {
                            artwork(result.preview, description: "Botanical bloom in \(BloomRenderer.palettes[result.parameters.palette].name), generated from the selected file. Three layers of curved petals surround a luminous seed core.")
                                .frame(width: artSize(in: viewport.size), height: artSize(in: viewport.size))
                                .frame(maxWidth: .infinity)
                            resultFooter(result)
                        } else {
                            welcome(width: viewport.size.width - 64)
                        }
                        Text("LOCAL BY DESIGN · YOUR FILE STAYS UNCHANGED")
                            .font(.caption).tracking(1)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 32).padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: viewport.size.height)
                }
            }
        }
        .background(background)
        .overlay {
            if targeted && model.canImport {
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(accent, style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
                    .padding(12)
                    .background(background.opacity(0.65))
                    .overlay {
                        Label("Drop one file to create its bloom", systemImage: "arrow.down.doc")
                            .font(.title2).padding(24).background(background, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .allowsHitTesting(false)
            }
        }
        .dropDestination(for: URL.self) { urls, _ in
            guard model.canImport else { return false }
            model.importFiles(urls)
            return true
        } isTargeted: { targeted = $0 }
        .frame(minWidth: 820, minHeight: 720)
        .preferredColorScheme(.dark)
        .tint(accent)
        .task { await model.loadDemonstration() }
        .onChange(of: model.message) { _, message in
            if let message { announce(message) }
        }
        .onChange(of: model.phase) { previous, phase in
            if previous == .rendering, phase == .idle, model.result != nil, model.message == nil {
                announce("Your bloom is ready. Explore the Bytes and Export PNG are available.")
            }
        }
    }

    private func announce(_ text: String) {
        NSAccessibility.post(element: NSApplication.shared, notification: .announcementRequested,
                             userInfo: [.announcement: text, .priority: NSAccessibilityPriorityLevel.high.rawValue])
    }

    // Size against the actual content viewport, not the window frame/title bar.
    // Details scroll instead of squeezing the square artwork or hiding controls.
    private func artSize(in viewport: CGSize) -> CGFloat {
        min(viewport.width - 64, max(340, min(600, viewport.height - 160)))
    }

    private var header: some View {
        ViewThatFits(in: .horizontal) {
            HStack { branding; Spacer(minLength: 24); headerActions }
            VStack(alignment: .leading, spacing: 12) { branding; headerActions }
        }
        .controlSize(.large)
        .padding(.horizontal, 32).padding(.vertical, 18)
    }

    private var branding: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("BYTEBLOOM").font(.headline).tracking(3)
            if model.result != nil {
                Text("Every file has a hidden beauty.").font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var headerActions: some View {
        HStack {
            if model.result != nil {
                Button(action: model.chooseFile) { Label("Choose Another File", systemImage: "doc.badge.plus") }
                    .disabled(!model.canImport)
                Button(action: model.chooseExport) { Label("Export PNG…", systemImage: "square.and.arrow.up") }
                    .buttonStyle(.borderedProminent)
                    .disabled(model.isBusy || model.isPanelPresented)
            }
        }
        .fixedSize()
    }

    @ViewBuilder private func welcome(width: CGFloat) -> some View {
        if width >= 720 {
            HStack(spacing: 24) {
                welcomeText.frame(width: 290)
                demonstration.frame(width: min(560, width - 314))
            }
        } else {
            VStack(spacing: 24) { welcomeText; demonstration.frame(maxWidth: 480) }
        }
    }

    private var welcomeText: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("Every file has\na hidden beauty.")
                .font(.system(size: 37, weight: .regular, design: .serif))
                .fixedSize(horizontal: false, vertical: true)
            Text("Turn the bytes of a file into\na luminous botanical artwork.")
                .font(.body).foregroundStyle(.secondary).lineSpacing(5)
            VStack(alignment: .leading, spacing: 14) {
                Label("Drop a file anywhere", systemImage: "arrow.down.doc")
                    .font(.body.weight(.medium))
                Button("Choose a File…", action: model.chooseFile)
                    .buttonStyle(.borderedProminent).controlSize(.large)
                    .disabled(!model.canImport)
                Text("One local file · up to 512 MiB")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 14))
            .overlay { RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.10)) }
        }
    }

    private var demonstration: some View {
        VStack(spacing: 0) {
            if let demo = model.demonstration {
                artwork(demo, description: "Demonstration botanical bloom from fixed synthetic bytes, not a selected file.")
            } else {
                ProgressView().frame(height: 360)
            }
            Text("DEMONSTRATION · SYNTHETIC BYTES")
                .font(.caption).tracking(1)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private func artwork(_ image: CGImage, description: String) -> some View {
        Image(image, scale: 1, label: Text(description))
            .resizable().interpolation(.high).scaledToFit()
    }

    private func resultFooter(_ result: BloomResult) -> some View {
        VStack(spacing: 14) {
            ViewThatFits(in: .horizontal) {
                HStack { resultSummary(result); Spacer(minLength: 24); exploreButton }
                VStack(alignment: .leading, spacing: 12) { resultSummary(result); exploreButton }
            }
            if exploring {
                ByteDetails(analysis: result.file.analysis, copy: model.copyFingerprint)
                    .padding(18)
                    .background(.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func resultSummary(_ result: BloomResult) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(result.file.source.url.lastPathComponent)
                .font(.title3.weight(.medium)).lineLimit(2).truncationMode(.middle)
            Text("\(ByteCountFormatter.string(fromByteCount: Int64(result.file.analysis.byteCount), countStyle: .binary))  ·  \(BloomRenderer.palettes[result.parameters.palette].name)  ·  bloom-v1")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private var exploreButton: some View {
        Button {
            exploring.toggle()
        } label: {
            Label("Explore the Bytes", systemImage: exploring ? "chevron.up" : "chevron.down")
        }
        .foregroundStyle(accent).fixedSize()
        .accessibilityValue(exploring ? "Expanded" : "Collapsed")
        .accessibilityHint("Shows or hides file size, entropy, fingerprint, and byte frequencies.")
    }

    private var progress: some View {
        HStack(spacing: 14) {
            ProgressView().controlSize(.small)
            VStack(alignment: .leading, spacing: 3) {
                Text(progressTitle).font(.body.weight(.medium))
                if model.phase == .analyzing {
                    Text("\(ByteCountFormatter.string(fromByteCount: Int64(model.bytesRead), countStyle: .binary)) read · \(model.importingName)")
                        .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
            }
            Spacer()
            Button(model.isCanceling ? "Canceling…" : "Cancel", action: model.cancel)
                .disabled(model.isCanceling)
        }
        .padding(14).background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 32).padding(.bottom, 8)
        .accessibilityElement(children: .contain)
    }

    private var progressTitle: String {
        switch model.phase {
        case .analyzing: "Reading your file locally…"
        case .rendering: "Growing your bloom…"
        case .exporting: "Preparing your 2048 × 2048 PNG…"
        case .idle: ""
        }
    }

    private func notice(_ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: model.isError ? "exclamationmark.circle" : "checkmark.circle")
                .foregroundStyle(model.isError ? Color.orange : accent)
                .accessibilityHidden(true)
            Text(text).font(.body).fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
            Button(action: model.dismissMessage) { Image(systemName: "xmark") }
                .accessibilityLabel("Dismiss message")
        }
        .padding(14).background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 32).padding(.bottom, 8)
    }
}

private struct ByteDetails: View {
    let analysis: BinaryAnalysis
    let copy: () -> Void
    private var bins: [UInt64] {
        (0..<16).map { analysis.histogram[($0 * 16)..<($0 * 16 + 16)].reduce(0, +) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 28) {
                    sizeAndEntropy
                    Spacer(minLength: 0)
                    fingerprint
                }.fixedSize(horizontal: true, vertical: false)
                VStack(alignment: .leading, spacing: 16) {
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .top, spacing: 28) { sizeAndEntropy }.fixedSize()
                        VStack(alignment: .leading, spacing: 16) { sizeAndEntropy }
                    }
                    fingerprint
                }
            }
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(0..<16, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(red: 0.45, green: 0.70, blue: 0.65).opacity(0.8))
                        .frame(height: bins[index] == 0 ? 0 : max(2, 44 * Double(bins[index]) / Double(max(1, bins.max() ?? 1))))
                        .frame(maxWidth: .infinity, maxHeight: 44, alignment: .bottom)
                        .help(String(format: "%02X–%02X: %@ bytes", index * 16, index * 16 + 15, bins[index].formatted()))
                }
            }
            // Virtual text children include zero-height bins, which otherwise have
            // no reliable accessibility hit area. Values are counts, not chart heights.
            .accessibilityRepresentation {
                VStack(alignment: .leading) {
                    ForEach(0..<16, id: \.self) { index in
                        Text("Byte values \(index * 16) through \(index * 16 + 15): \(bins[index].formatted()) occurrences")
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel("Byte values \(index * 16) through \(index * 16 + 15)")
                            .accessibilityValue("\(bins[index].formatted()) occurrences")
                    }
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Byte frequency histogram. 16 groups of consecutive byte values.")
            }
            HStack {
                Text("00")
                Spacer()
                Text("BYTE FREQUENCY · 16 GROUPS")
                Spacer()
                Text("FF")
            }.font(.caption.monospaced()).foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text("Entropy measures byte-value distribution, not randomness, compression, encryption, malware, or security.")
                .font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder private var sizeAndEntropy: some View {
        metric("FILE SIZE", value: "\(analysis.byteCount.formatted()) bytes")
        metric("SHANNON ENTROPY", value: String(format: "%.4f / 8 bits per byte", analysis.entropy))
    }

    private func metric(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.caption.weight(.medium)).tracking(1).foregroundStyle(.secondary)
            Text(value).font(.body.monospacedDigit()).textSelection(.enabled)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(value)
    }

    private var fingerprint: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("SHA-256").font(.caption.weight(.medium)).tracking(1).foregroundStyle(.secondary)
            HStack {
                Text(String(analysis.fingerprint.prefix(12)) + "…" + analysis.fingerprint.suffix(8))
                    .font(.body.monospaced())
                    .accessibilityLabel("Abbreviated SHA-256: \(analysis.fingerprint.prefix(12)) through \(analysis.fingerprint.suffix(8))")
                Button(action: copy) { Image(systemName: "doc.on.doc") }
                    .help("Copy full SHA-256 fingerprint")
                    .accessibilityLabel("Copy full SHA-256 fingerprint")
            }
        }
    }
}
