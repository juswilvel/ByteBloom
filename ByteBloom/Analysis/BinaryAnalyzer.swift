import Foundation
import CryptoKit

struct BinaryAnalysis: Equatable, Sendable {
    let byteCount: UInt64
    let sha256: [UInt8]
    let histogram: [UInt64]
    let entropy: Double

    var fingerprint: String {
        sha256.map { String(format: "%02x", $0) }.joined()
    }

    fileprivate init(byteCount: UInt64, sha256: [UInt8], histogram: [UInt64], entropy: Double) {
        self.byteCount = byteCount
        self.sha256 = sha256
        self.histogram = histogram
        self.entropy = entropy
    }
}

enum AnalysisError: Error, Equatable, LocalizedError {
    case emptyFile, oversizedFile, unsupportedFile, unavailableFile, fileChanged

    var errorDescription: String? {
        switch self {
        case .emptyFile: "This file is empty. Choose a file containing at least one byte."
        case .oversizedFile: "Choose a file no larger than 512 MiB."
        case .unsupportedFile: "Choose a regular file. Folders, apps, aliases, and symbolic links aren't supported."
        case .unavailableFile: "This file isn't available locally. Download it in Finder and try again."
        case .fileChanged: "The file changed while it was being read. Try importing it again."
        }
    }
}

/// Synchronous streaming core: callers schedule it off the UI actor (see FileAccess).
/// Owns neither file permissions nor handles and retains only one chunk plus 256 counters.
enum BinaryAnalyzer {
    static let chunkSize = 1_048_576
    static let maximumByteCount: UInt64 = 536_870_912

    static func analyze(
        expectedByteCount: UInt64? = nil,
        readChunk: (Int) throws -> Data,
        progress: (UInt64) -> Void = { _ in }
    ) throws -> BinaryAnalysis {
        var hash = SHA256()
        var histogram = [UInt64](repeating: 0, count: 256)
        var count: UInt64 = 0
        let clock = ContinuousClock()
        var lastUpdate = clock.now
        while true {
            try Task.checkCancellation()
            let chunk = try readChunk(chunkSize)
            guard !chunk.isEmpty else { break }
            guard UInt64(chunk.count) <= maximumByteCount - count else {
                throw AnalysisError.oversizedFile
            }
            hash.update(data: chunk)
            for byte in chunk { histogram[Int(byte)] += 1 }
            count += UInt64(chunk.count)
            if clock.now - lastUpdate >= .milliseconds(100) {
                progress(count)
                lastUpdate = clock.now
            }
        }
        try Task.checkCancellation()
        if let expectedByteCount, expectedByteCount != count { throw AnalysisError.fileChanged }
        guard count > 0 else { throw AnalysisError.emptyFile }
        var entropy = 0.0
        // Ascending byte order is deliberate: stable floating-point summation order.
        for frequency in histogram where frequency > 0 {
            let p = Double(frequency) / Double(count)
            entropy -= p * log2(p)
        }
        progress(count)
        return BinaryAnalysis(byteCount: count, sha256: Array(hash.finalize()),
                              histogram: histogram, entropy: min(8, max(0, entropy)))
    }
}
