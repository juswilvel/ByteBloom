import Foundation
import Darwin

/// File eligibility, read-only handle lifetime, and security scope live at this boundary.
enum FileAccess {
    static func analyze(
        _ url: URL,
        progress: @escaping @Sendable (UInt64) -> Void = { _ in }
    ) async throws -> BinaryAnalysis {
        let worker = Task.detached(priority: .userInitiated) {
            try Task.checkCancellation()
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            return try withReadableFile(url) { handle, size in
                try BinaryAnalyzer.analyze(expectedByteCount: size, readChunk: {
                    try handle.read(upToCount: $0) ?? Data()
                }, progress: progress)
            }
        }
        return try await withTaskCancellationHandler {
            try await worker.value
        } onCancel: {
            worker.cancel()
        }
    }

    static func withReadableFile<T>(_ url: URL, body: (FileHandle, UInt64) throws -> T) throws -> T {
        guard url.isFileURL else { throw AnalysisError.unsupportedFile }
        let values = try url.resourceValues(forKeys: [
            .isRegularFileKey, .isSymbolicLinkKey, .isAliasFileKey,
            .isPackageKey, .isUbiquitousItemKey, .ubiquitousItemDownloadingStatusKey
        ])
        guard values.isRegularFile == true, values.isSymbolicLink != true,
              values.isAliasFile != true, values.isPackage != true else {
            throw AnalysisError.unsupportedFile
        }
        if values.isUbiquitousItem == true,
           values.ubiquitousItemDownloadingStatus != .current,
           values.ubiquitousItemDownloadingStatus != .downloaded {
            throw AnalysisError.unavailableFile
        }
        // NOFOLLOW prevents a final-component symlink swap; NONBLOCK avoids blocking
        // on a FIFO substituted between resource inspection and open. fstat revalidates.
        let descriptor = url.withUnsafeFileSystemRepresentation { path in
            path.map { Darwin.open($0, O_RDONLY | O_NOFOLLOW | O_NONBLOCK | O_CLOEXEC) } ?? -1
        }
        guard descriptor >= 0 else { throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO) }
        let handle = FileHandle(fileDescriptor: descriptor, closeOnDealloc: true)
        defer { try? handle.close() }
        let before = try snapshot(descriptor)
        guard before.st_mode & S_IFMT == S_IFREG else { throw AnalysisError.unsupportedFile }
        guard before.st_size > 0 else { throw AnalysisError.emptyFile }
        guard before.st_size <= BinaryAnalyzer.maximumByteCount else { throw AnalysisError.oversizedFile }
        let result = try body(handle, UInt64(before.st_size))
        try Task.checkCancellation()
        let after = try snapshot(descriptor)
        guard before.st_size == after.st_size,
              before.st_mtimespec.tv_sec == after.st_mtimespec.tv_sec,
              before.st_mtimespec.tv_nsec == after.st_mtimespec.tv_nsec,
              before.st_ctimespec.tv_sec == after.st_ctimespec.tv_sec,
              before.st_ctimespec.tv_nsec == after.st_ctimespec.tv_nsec else {
            throw AnalysisError.fileChanged
        }
        // Best effort only: this is not an atomic snapshot of a concurrently edited file.
        return result
    }

    private static func snapshot(_ descriptor: Int32) throws -> stat {
        var value = stat()
        guard fstat(descriptor, &value) == 0 else {
            throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
        }
        return value
    }
}
