import XCTest
@testable import ByteBloom

func analyzeBytes(_ data: Data, chunkSize: Int = BinaryAnalyzer.chunkSize) throws -> BinaryAnalysis {
    var offset = 0
    return try BinaryAnalyzer.analyze { requested in
        let end = min(data.count, offset + min(chunkSize, requested))
        defer { offset = end }
        return data.subdata(in: offset..<end)
    }
}

final class BinaryAnalyzerTests: XCTestCase {
    func testEmptyIsExplicitlyUnsupported() {
        XCTAssertThrowsError(try analyzeBytes(Data())) { XCTAssertEqual($0 as? AnalysisError, .emptyFile) }
    }

    func testOneByteAndRepeatedBytes() throws {
        for count in [1, 4097, 1_048_577] {
            let result = try analyzeBytes(Data(repeating: 42, count: count))
            XCTAssertEqual(result.byteCount, UInt64(count))
            XCTAssertEqual(result.entropy, 0)
            XCTAssertEqual(result.histogram.count, 256)
            XCTAssertEqual(result.histogram[42], UInt64(count))
            XCTAssertEqual(result.histogram.reduce(0, +), result.byteCount)
        }
    }

    func testUniformDistribution() throws {
        let result = try analyzeBytes(Data((0..<4096).map { UInt8($0 % 256) }))
        XCTAssertEqual(result.entropy, 8, accuracy: 1e-14)
        XCTAssertEqual(result.histogram, [UInt64](repeating: 16, count: 256))
    }

    func testKnownSHA256Vectors() throws {
        let vectors = [
            ("a", "ca978112ca1bbdcafac231b39a23dc4da786eff8147c4e72b9807785afee48bb"),
            ("abc", "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"),
            ("The quick brown fox jumps over the lazy dog", "d7a8fbb307d7809469ca9abcb0082e4f8d5651e46d3cdb762d02d0bf37c9e592")
        ]
        for (input, expected) in vectors {
            XCTAssertEqual(try analyzeBytes(Data(input.utf8)).fingerprint, expected)
        }
        XCTAssertEqual(try analyzeBytes(Data(repeating: 97, count: 1_000_000)).fingerprint,
                       "cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0")
    }

    func testEntropyReferenceAndChunkBoundaries() throws {
        let reference = try analyzeBytes(Data([0, 0, 0, 1]))
        XCTAssertEqual(reference.entropy, 0.8112781244591328, accuracy: 1e-14)
        let data = Data((0..<1_048_589).map { UInt8($0 % 251) })
        let expected = try analyzeBytes(data)
        for size in [13, 65_537, 1_048_576] {
            XCTAssertEqual(try analyzeBytes(data, chunkSize: size), expected)
        }
        XCTAssertEqual(expected.histogram.reduce(0, +), expected.byteCount)
    }

    func testChangedSizeAndReadFailure() {
        XCTAssertThrowsError(try BinaryAnalyzer.analyze(expectedByteCount: 3, readChunk: { _ in Data() })) {
            XCTAssertEqual($0 as? AnalysisError, .fileChanged)
        }
        XCTAssertThrowsError(try BinaryAnalyzer.analyze(readChunk: { _ in throw CocoaError(.fileReadNoPermission) }))
    }

    func testCancellationBeforeReading() async throws {
        let task = Task.detached {
            withUnsafeCurrentTask { $0?.cancel() }
            return try BinaryAnalyzer.analyze { _ in XCTFail("Canceled work must not read"); return Data() }
        }
        do { _ = try await task.value; XCTFail("Expected cancellation") }
        catch { XCTAssertTrue(error is CancellationError) }
    }

    func testCancellationBetweenReads() async throws {
        let task = Task.detached {
            var reads = 0
            do {
                _ = try BinaryAnalyzer.analyze { _ in
                    reads += 1
                    withUnsafeCurrentTask { $0?.cancel() }
                    return Data(repeating: 7, count: 1024)
                }
                XCTFail("Expected cancellation")
            } catch { XCTAssertTrue(error is CancellationError) }
            XCTAssertEqual(reads, 1)
        }
        await task.value
    }
}

final class FileAccessTests: XCTestCase {
    func testRegularFilesRenamingAndRejections() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let first = directory.appendingPathComponent("first.bin")
        let second = directory.appendingPathComponent("different-name.dat")
        let data = Data("safe synthetic bytes".utf8)
        try data.write(to: first)
        try data.write(to: second)
        func read(_ url: URL) throws -> BinaryAnalysis {
            try FileAccess.withReadableFile(url) { handle, size in
                try BinaryAnalyzer.analyze(expectedByteCount: size) { try handle.read(upToCount: $0) ?? Data() }
            }
        }
        XCTAssertEqual(try read(first), try read(second))
        XCTAssertEqual(try Data(contentsOf: first), data)
        XCTAssertThrowsError(try read(directory))
        let link = directory.appendingPathComponent("link")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: first)
        XCTAssertThrowsError(try read(link)) { XCTAssertEqual($0 as? AnalysisError, .unsupportedFile) }
        try Data().write(to: second)
        XCTAssertThrowsError(try read(second)) { XCTAssertEqual($0 as? AnalysisError, .emptyFile) }
        let handle = try FileHandle(forWritingTo: second)
        try handle.truncate(atOffset: BinaryAnalyzer.maximumByteCount + 1)
        try handle.close()
        XCTAssertThrowsError(try read(second)) { XCTAssertEqual($0 as? AnalysisError, .oversizedFile) }
    }

    func testModificationDetected() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: url) }
        try Data([1, 2, 3]).write(to: url)
        XCTAssertThrowsError(try FileAccess.withReadableFile(url) { _, _ in
            let writer = try FileHandle(forWritingTo: url)
            try writer.truncate(atOffset: 2)
            try writer.close()
        }) { XCTAssertEqual($0 as? AnalysisError, .fileChanged) }
    }
}
