import Foundation
import Darwin

/// Filesystem identity is used only for overwrite protection, never for artwork.
struct FileIdentity: Equatable, Sendable {
    let device: Int32
    let inode: UInt64

    init(_ value: stat) {
        device = value.st_dev
        inode = value.st_ino
    }
}

struct SourceFile: Sendable {
    let url: URL
    let canonicalPath: String
    let identity: FileIdentity
}

struct AnalyzedFile: Sendable {
    let analysis: BinaryAnalysis
    let source: SourceFile
}
