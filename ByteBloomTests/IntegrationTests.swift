import XCTest
import ImageIO
@testable import ByteBloom

private func fixtureDirectory() throws -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("ByteBloom-tests-" + UUID().uuidString)
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

final class PNGExportTests: XCTestCase {
    func testUnavailableAndUnreadableInputs() async throws {
        let directory = try fixtureDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let missing = directory.appendingPathComponent("missing.bin")
        do { _ = try await FileAccess.analyzeSource(missing); XCTFail("Missing file must fail") }
        catch { XCTAssertFalse(error is CancellationError) }
        let restricted = directory.appendingPathComponent("unreadable.bin")
        try Data([1, 2, 3]).write(to: restricted)
        try FileManager.default.setAttributes([.posixPermissions: 0], ofItemAtPath: restricted.path)
        defer { try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: restricted.path) }
        do { _ = try await FileAccess.analyzeSource(restricted); XCTFail("Unreadable file must fail") }
        catch { XCTAssertFalse(error is CancellationError) }
    }

    func testExportAndOverwriteProtection() async throws {
        let directory = try fixtureDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let sourceURL = directory.appendingPathComponent("source.bin")
        let bytes = Data("Export integration fixture".utf8)
        try bytes.write(to: sourceURL)
        let file = try await FileAccess.analyzeSource(sourceURL)
        let parameters = BloomGeneratorV1.generate(from: file.analysis)
        let output = directory.appendingPathComponent("bloom.png")
        try await PNGExport.save(parameters, to: output, protecting: file.source)
        let imageSource = try XCTUnwrap(CGImageSourceCreateWithURL(output as CFURL, nil))
        let image = try XCTUnwrap(CGImageSourceCreateImageAtIndex(imageSource, 0, nil))
        XCTAssertEqual(image.width, 2048)
        XCTAssertEqual(image.height, 2048)
        XCTAssertEqual(image.colorSpace?.name, CGColorSpace.sRGB)
        XCTAssertEqual(try Data(contentsOf: output)[25], 2)
        XCTAssertEqual(try Data(contentsOf: sourceURL), bytes)
        XCTAssertThrowsError(try PNGExport.validateDestination(sourceURL, protecting: file.source))
        let hardLink = directory.appendingPathComponent("hard-link.png")
        try FileManager.default.linkItem(at: sourceURL, to: hardLink)
        XCTAssertThrowsError(try PNGExport.validateDestination(hardLink, protecting: file.source))
        let symbolicLink = directory.appendingPathComponent("symbolic-link.png")
        try FileManager.default.createSymbolicLink(at: symbolicLink, withDestinationURL: sourceURL)
        XCTAssertThrowsError(try PNGExport.validateDestination(symbolicLink, protecting: file.source))
        let alias = directory.appendingPathComponent("alias.png")
        let bookmark = try sourceURL.bookmarkData(options: .suitableForBookmarkFile)
        try URL.writeBookmarkData(bookmark, to: alias)
        XCTAssertThrowsError(try PNGExport.validateDestination(alias, protecting: file.source))
        XCTAssertThrowsError(try FileAccess.withReadableFile(alias) { _, _ in })
        // Protection follows the imported inode even after its name changes.
        let moved = directory.appendingPathComponent("moved.png")
        try FileManager.default.moveItem(at: sourceURL, to: moved)
        XCTAssertThrowsError(try PNGExport.validateDestination(moved, protecting: file.source))
        XCTAssertEqual(try Data(contentsOf: moved), bytes)
    }

    func testDestinationReplacementRaceAndCanceledWrite() async throws {
        let directory = try fixtureDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let source = directory.appendingPathComponent("input")
        try Data([1, 2, 3]).write(to: source)
        let file = try await FileAccess.analyzeSource(source)
        let destination = directory.appendingPathComponent("output.png")
        let expected = try PNGExport.validateDestination(destination, protecting: file.source)
        let existing = Data("Keep the unapproved new destination".utf8)
        try existing.write(to: destination)
        XCTAssertThrowsError(try PNGExport.write(Data([4]), to: destination, protecting: file.source, expected: expected))
        XCTAssertEqual(try Data(contentsOf: destination), existing)
        let parameters = BloomGeneratorV1.generate(from: file.analysis)
        let canceled = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            try await PNGExport.save(parameters, to: destination, protecting: file.source)
        }
        do { try await canceled.value; XCTFail("Expected cancellation") }
        catch { XCTAssertTrue(error is CancellationError) }
        XCTAssertEqual(try Data(contentsOf: destination), existing)
        // Explicit replacement of an unrelated destination remains supported.
        try await PNGExport.save(parameters, to: destination, protecting: file.source)
        XCTAssertEqual(try Data(contentsOf: destination)[25], 2)
    }
}

@MainActor final class BloomModelTests: XCTestCase {
    private func waitUntil(_ predicate: () -> Bool) async throws {
        let deadline = ContinuousClock.now + .seconds(10)
        while !predicate(), ContinuousClock.now < deadline { try await Task.sleep(for: .milliseconds(10)) }
        XCTAssertTrue(predicate(), "Operation did not reach expected state")
    }

    func testFailedAndCanceledImportPreserveResult() async throws {
        let directory = try fixtureDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let good = directory.appendingPathComponent("good.bin")
        let empty = directory.appendingPathComponent("empty.bin")
        try Data("previous successful bloom".utf8).write(to: good)
        try Data().write(to: empty)
        let model = BloomModel()
        model.importFiles([good])
        try await waitUntil { !model.isBusy }
        let fingerprint = try XCTUnwrap(model.result?.file.analysis.fingerprint)
        model.importFiles([empty])
        try await waitUntil { !model.isBusy }
        XCTAssertTrue(model.isError)
        XCTAssertEqual(model.result?.file.analysis.fingerprint, fingerprint)
        model.importFiles([good, empty])
        XCTAssertTrue(model.isError)
        XCTAssertEqual(model.result?.file.analysis.fingerprint, fingerprint)
        model.importFiles([good])
        model.cancel()
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertFalse(model.isBusy)
        XCTAssertEqual(model.result?.file.analysis.fingerprint, fingerprint)
        XCTAssertEqual(model.message, "Import canceled.")
    }

    func testActiveImportReplacementCannotPublishStaleResult() async throws {
        let directory = try fixtureDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let slow = directory.appendingPathComponent("large.bin")
        let latest = directory.appendingPathComponent("latest.bin")
        try Data([0]).write(to: slow)
        let handle = try FileHandle(forWritingTo: slow)
        try handle.truncate(atOffset: BinaryAnalyzer.maximumByteCount)
        try handle.close()
        try Data("latest result must win".utf8).write(to: latest)
        let model = BloomModel()
        model.importFiles([slow])
        try await waitUntil { model.bytesRead > 0 || !model.isBusy }
        XCTAssertTrue(model.isBusy, "Fixture must exercise replacement during active work")
        model.importFiles([latest])
        try await waitUntil { !model.isBusy }
        try await Task.sleep(for: .milliseconds(150))
        XCTAssertEqual(model.result?.file.source.url, latest)
        XCTAssertEqual(model.result?.file.analysis.fingerprint, try analyzeBytes(Data("latest result must win".utf8)).fingerprint)
        XCTAssertFalse(model.isError)
    }
}
