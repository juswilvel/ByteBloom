import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import Darwin

enum ExportError: Error, LocalizedError {
    case sourceOverwrite, unsupportedDestination, destinationChanged, encodingFailed

    var errorDescription: String? {
        switch self {
        case .sourceOverwrite: "Your original file is protected. Choose a different name or location for the PNG."
        case .unsupportedDestination: "Choose a regular PNG destination, not a folder, alias, or symbolic link."
        case .destinationChanged: "The destination changed while the artwork was being prepared. Choose a location again."
        case .encodingFailed: "The PNG couldn't be created. Please try exporting again."
        }
    }
}

/// Rendering/encoding run on a worker. Security scope covers destination inspection
/// and the coordinated atomic write. Only the native save panel authorizes replacement.
enum PNGExport {
    static func save(_ parameters: BloomParameters, to url: URL, protecting source: SourceFile) async throws {
        let worker = Task.detached(priority: .userInitiated) {
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            try Task.checkCancellation()
            let expected = try validateDestination(url, protecting: source)
            let image = try BloomRenderer.render(parameters, pixelSize: 2048)
            let data = try encode(image)
            try Task.checkCancellation()
            try write(data, to: url, protecting: source, expected: expected)
        }
        try await withTaskCancellationHandler {
            try await worker.value
        } onCancel: {
            worker.cancel()
        }
    }

    static func encode(_ image: CGImage) throws -> Data {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil) else {
            throw ExportError.encodingFailed
        }
        // Supply only the rendered bitmap, never any imported-file metadata.
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else { throw ExportError.encodingFailed }
        return data as Data
    }

    /// nil means absent. Fail closed on permission/stat errors; never treat them as absence.
    static func validateDestination(_ url: URL, protecting source: SourceFile) throws -> FileIdentity? {
        guard url.isFileURL else { throw ExportError.unsupportedDestination }
        let path = url.resolvingSymlinksInPath().standardizedFileURL.path
        guard path != source.canonicalPath,
              url.standardizedFileURL.path != source.url.standardizedFileURL.path else { throw ExportError.sourceOverwrite }
        var info = stat()
        let status = url.withUnsafeFileSystemRepresentation { pointer in
            pointer.map { lstat($0, &info) } ?? -1
        }
        if status != 0 {
            guard errno == ENOENT else { throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO) }
            return nil
        }
        guard info.st_mode & S_IFMT == S_IFREG else { throw ExportError.unsupportedDestination }
        let identity = FileIdentity(info)
        guard identity != source.identity else { throw ExportError.sourceOverwrite }
        let values = try url.resourceValues(forKeys: [.isAliasFileKey])
        guard values.isAliasFile != true else { throw ExportError.unsupportedDestination }
        return identity
    }

    static func write(_ data: Data, to url: URL, protecting source: SourceFile, expected: FileIdentity?) throws {
        var coordinationError: NSError?
        var writeError: Error?
        NSFileCoordinator().coordinate(writingItemAt: url, options: .forReplacing, error: &coordinationError) { coordinatedURL in
            do {
                guard try validateDestination(coordinatedURL, protecting: source) == expected else {
                    throw ExportError.destinationChanged
                }
                try Task.checkCancellation()
                // Atomic replacement never truncates a destination's existing hard-linked inode.
                // Cancellation after this commit point reports success if the write completed.
                try data.write(to: coordinatedURL, options: .atomic)
            } catch { writeError = error }
        }
        if let coordinationError { throw coordinationError }
        if let writeError { throw writeError }
    }
}
