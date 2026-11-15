import AppKit
import Observation
import UniformTypeIdentifiers

struct BloomResult: Sendable {
    let file: AnalyzedFile
    let parameters: BloomParameters
    let preview: CGImage
}

@MainActor @Observable
final class BloomModel {
    enum Phase: Equatable { case idle, analyzing, rendering, exporting }
    private(set) var phase = Phase.idle
    private(set) var result: BloomResult?
    private(set) var demonstration: CGImage?
    private(set) var bytesRead: UInt64 = 0
    private(set) var importingName = ""
    private(set) var message: String?
    private(set) var isError = false
    private(set) var isPanelPresented = false
    private(set) var isCanceling = false
    private var operation: Task<Void, Never>?
    private var generation: UInt64 = 0

    var isBusy: Bool { phase != .idle }
    var canImport: Bool { phase != .exporting && !isPanelPresented }

    private var presentationWindow: NSWindow? {
        NSApp.mainWindow ?? NSApp.windows.first { $0.isVisible && $0.canBecomeMain }
    }

    func loadDemonstration() async {
        guard demonstration == nil else { return }
        demonstration = try? await Task.detached(priority: .utility) {
            let data = Data(String(repeating: "Every file has a hidden beauty.\n", count: 4096).utf8)
            var consumed = false
            let analysis = try BinaryAnalyzer.analyze { _ in
                defer { consumed = true }
                return consumed ? Data() : data
            }
            return try BloomRenderer.render(BloomGeneratorV1.generate(from: analysis), pixelSize: 1024)
        }.value
    }

    func chooseFile() {
        guard canImport, let window = presentationWindow else { return }
        let panel = NSOpenPanel()
        panel.title = "Choose a file to bloom"
        panel.prompt = "Create Bloom"
        panel.message = "Choose one local file, from 1 byte to 512 MiB. Your file stays unchanged."
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.resolvesAliases = false
        isPanelPresented = true
        panel.beginSheetModal(for: window) { [weak self] response in
            guard let self else { return }
            self.isPanelPresented = false
            if response == .OK { self.importFiles(panel.urls) }
        }
    }

    func importFiles(_ urls: [URL]) {
        guard canImport else { return }
        stopImport()
        guard urls.count == 1, let url = urls.first else {
            fail("Drop one file at a time. Choose a single file to create its bloom.")
            return
        }
        let ticket = generation
        phase = .analyzing
        bytesRead = 0
        importingName = url.lastPathComponent
        message = nil
        isError = false
        operation = Task { [weak self] in
            do {
                let file = try await FileAccess.analyzeSource(url) { [weak self] count in
                    Task { @MainActor [weak self] in
                        guard let self, self.generation == ticket, self.phase == .analyzing else { return }
                        self.bytesRead = count
                    }
                }
                try Task.checkCancellation()
                guard let self, self.generation == ticket else { return }
                self.phase = .rendering
                let rendered = try await Self.makeResult(file)
                try Task.checkCancellation()
                guard self.generation == ticket else { return }
                self.result = rendered
                self.phase = .idle
                self.operation = nil
            } catch {
                guard let self, self.generation == ticket else { return }
                self.phase = .idle
                self.operation = nil
                if error is CancellationError {
                    self.message = "Import canceled."
                } else {
                    self.fail(error.localizedDescription)
                }
            }
        }
    }

    private static func makeResult(_ file: AnalyzedFile) async throws -> BloomResult {
        let worker = Task.detached(priority: .userInitiated) {
            try Task.checkCancellation()
            let parameters = BloomGeneratorV1.generate(from: file.analysis)
            let image = try BloomRenderer.render(parameters, pixelSize: 1024)
            return BloomResult(file: file, parameters: parameters, preview: image)
        }
        return try await withTaskCancellationHandler {
            try await worker.value
        } onCancel: { worker.cancel() }
    }

    func cancel() {
        if phase == .exporting {
            // Await the worker: a write that passed its atomic commit point may succeed.
            isCanceling = true
            operation?.cancel()
        } else {
            stopImport()
            message = "Import canceled."
            isError = false
        }
    }

    private func stopImport() {
        generation &+= 1
        operation?.cancel()
        operation = nil
        phase = .idle
    }

    func chooseExport() {
        guard result != nil, !isBusy, !isPanelPresented, let window = presentationWindow else { return }
        let panel = NSSavePanel()
        panel.title = "Export your bloom"
        panel.nameFieldStringValue = "ByteBloom.png"
        panel.allowedContentTypes = [.png]
        panel.canCreateDirectories = true
        panel.message = "2048 × 2048 pixels · opaque sRGB PNG"
        isPanelPresented = true
        panel.beginSheetModal(for: window) { [weak self] response in
            guard let self else { return }
            self.isPanelPresented = false
            if response == .OK, let url = panel.url { self.export(to: url) }
        }
    }

    /// The caller must obtain replacement consent through NSSavePanel before invoking.
    func export(to url: URL) {
        guard let result, !isBusy else { return }
        phase = .exporting
        isCanceling = false
        message = nil
        isError = false
        operation = Task { [weak self] in
            do {
                try await PNGExport.save(result.parameters, to: url, protecting: result.file.source)
                self?.message = "Saved \(url.lastPathComponent) · 2048 × 2048 PNG"
            } catch {
                if error is CancellationError {
                    self?.message = "Export canceled."
                } else {
                    self?.fail(error.localizedDescription)
                }
            }
            self?.phase = .idle
            self?.isCanceling = false
            self?.operation = nil
        }
    }

    func copyFingerprint() {
        guard let result else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(result.file.analysis.fingerprint, forType: .string)
        message = "SHA-256 copied."
        isError = false
    }

    func dismissMessage() { message = nil; isError = false }

    private func fail(_ text: String) {
        phase = .idle
        message = text
        isError = true
    }
}
