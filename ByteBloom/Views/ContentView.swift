import SwiftUI

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
            if let result = model.result {
                artwork(result.preview)
                    .padding(.horizontal, 28)
                    .padding(.top, 8)
                resultFooter(result)
            } else {
                welcome
            }
            Text("LOCAL BY DESIGN  ·  YOUR FILE STAYS UNCHANGED")
                .font(.system(size: 9, weight: .medium)).tracking(1.8)
                .foregroundStyle(.secondary.opacity(0.65))
                .padding(.bottom, 16).padding(.top, 12)
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
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text("BYTEBLOOM").font(.system(size: 15, weight: .semibold)).tracking(3)
                if model.result != nil {
                    Text("Every file has a hidden beauty.").font(.system(size: 12)).foregroundStyle(.secondary)
                }
            }
            Spacer()
            if model.result != nil {
                Button(action: model.chooseFile) { Label("Choose Another File", systemImage: "doc.badge.plus") }
                    .disabled(!model.canImport)
                Button(action: model.chooseExport) { Label("Export PNG…", systemImage: "square.and.arrow.up") }
                    .buttonStyle(.borderedProminent)
                    .disabled(model.isBusy || model.isPanelPresented)
            }
        }
        .controlSize(.large)
        .padding(.horizontal, 32).padding(.vertical, 18)
    }

    private var welcome: some View {
        HStack(spacing: 4) {
            VStack(alignment: .leading, spacing: 22) {
                Text("Every file has\na hidden beauty.")
                    .font(.system(size: 37, weight: .regular, design: .serif))
                    .fixedSize(horizontal: false, vertical: true)
                Text("Turn the bytes of a file into\na luminous botanical artwork.")
                    .font(.system(size: 15)).foregroundStyle(.secondary).lineSpacing(5)
                VStack(alignment: .leading, spacing: 14) {
                    Label("Drop a file anywhere", systemImage: "arrow.down.doc")
                        .font(.system(size: 15, weight: .medium))
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
            .frame(width: 290).padding(.leading, 38)
            VStack(spacing: 0) {
                if let demo = model.demonstration {
                    artwork(demo)
                } else {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                Text("DEMONSTRATION · SYNTHETIC BYTES")
                    .font(.system(size: 9, weight: .medium)).tracking(1.5)
                    .foregroundStyle(.secondary)
            }
            .padding(.trailing, 12)
        }
        .padding(.bottom, 24)
        .frame(maxHeight: .infinity)
    }

    private func artwork(_ image: CGImage) -> some View {
        Image(decorative: image, scale: 1)
            .resizable().interpolation(.high).scaledToFit()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityLabel(model.result == nil ? "Demonstration botanical bloom" : "Botanical bloom generated from the selected file")
            .accessibilityHidden(false)
    }

    private func resultFooter(_ result: BloomResult) -> some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(result.file.source.url.lastPathComponent)
                        .font(.system(size: 17, weight: .medium)).lineLimit(1).truncationMode(.middle)
                    Text("\(ByteCountFormatter.string(fromByteCount: Int64(result.file.analysis.byteCount), countStyle: .binary))  ·  \(BloomRenderer.palettes[result.parameters.palette].name)  ·  bloom-v1")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer(minLength: 16)
                Button {
                    exploring.toggle()
                } label: {
                    Label("Explore the Bytes", systemImage: exploring ? "chevron.up" : "chevron.down")
                }
                .buttonStyle(.plain).foregroundStyle(accent)
                .accessibilityValue(exploring ? "Expanded" : "Collapsed")
            }
            if exploring {
                ByteDetails(analysis: result.file.analysis, copy: model.copyFingerprint)
                    .padding(18)
                    .background(.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.horizontal, 36).padding(.top, 12)
    }

    private var progress: some View {
        HStack(spacing: 14) {
            ProgressView().controlSize(.small)
            VStack(alignment: .leading, spacing: 3) {
                Text(progressTitle).font(.system(size: 13, weight: .medium))
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
            Text(text).font(.system(size: 13)).fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
            Button(action: model.dismissMessage) { Image(systemName: "xmark") }
                .buttonStyle(.plain).accessibilityLabel("Dismiss message")
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
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 28) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("FILE SIZE").font(.system(size: 9, weight: .medium)).tracking(1.3).foregroundStyle(.secondary)
                    Text("\(analysis.byteCount.formatted()) bytes").font(.system(size: 13).monospacedDigit()).textSelection(.enabled)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("SHANNON ENTROPY").font(.system(size: 9, weight: .medium)).tracking(1.3).foregroundStyle(.secondary)
                    Text(String(format: "%.4f / 8 bits per byte", analysis.entropy)).font(.system(size: 13).monospacedDigit())
                }
                Spacer(minLength: 0)
                VStack(alignment: .leading, spacing: 4) {
                    Text("SHA-256").font(.system(size: 9, weight: .medium)).tracking(1.3).foregroundStyle(.secondary)
                    HStack {
                        Text(String(analysis.fingerprint.prefix(12)) + "…" + analysis.fingerprint.suffix(8))
                            .font(.system(size: 12, design: .monospaced))
                        Button(action: copy) { Image(systemName: "doc.on.doc") }
                            .buttonStyle(.plain).help("Copy full SHA-256 fingerprint")
                            .accessibilityLabel("Copy full SHA-256 fingerprint")
                    }
                }
            }
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(0..<16, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(red: 0.45, green: 0.70, blue: 0.65).opacity(0.8))
                        .frame(height: bins[index] == 0 ? 0 : max(2, 44 * Double(bins[index]) / Double(max(1, bins.max() ?? 1))))
                        .frame(maxWidth: .infinity, maxHeight: 44, alignment: .bottom)
                        .help(String(format: "%02X–%02X: %@ bytes", index * 16, index * 16 + 15, bins[index].formatted()))
                        .accessibilityLabel("Byte values \(index * 16) through \(index * 16 + 15): \(bins[index]) occurrences")
                }
            }
            HStack {
                Text("00")
                Spacer()
                Text("BYTE FREQUENCY · 16 GROUPS")
                Spacer()
                Text("FF")
            }.font(.system(size: 9, design: .monospaced)).foregroundStyle(.secondary)
            Text("Entropy measures byte-value distribution, not randomness, compression, encryption, malware, or security.")
                .font(.system(size: 11)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        }
    }
}
