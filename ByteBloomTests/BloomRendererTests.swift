import XCTest
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
@testable import ByteBloom

final class BloomRendererTests: XCTestCase {
    func testRenderDimensionsColorSpaceAndRepeatability() throws {
        let parameters = BloomGeneratorV1.generate(from: try analyzeBytes(Data("abc".utf8)))
        let first = try BloomRenderer.render(parameters, pixelSize: 256)
        let second = try BloomRenderer.render(parameters, pixelSize: 256)
        XCTAssertEqual(first.width, 256)
        XCTAssertEqual(first.height, 256)
        XCTAssertEqual(first.colorSpace?.name, CGColorSpace.sRGB)
        XCTAssertEqual(first.alphaInfo, .noneSkipLast)
        XCTAssertEqual(first.dataProvider?.data as Data?, second.dataProvider?.data as Data?)
        let pixels = try XCTUnwrap(first.dataProvider?.data as Data?)
        // A nonblank image with dark corners and a brighter focal point.
        let center = (128 * 256 + 128) * 4
        XCTAssertGreaterThan(Int(pixels[center]) + Int(pixels[center + 1]) + Int(pixels[center + 2]),
                             Int(pixels[0]) + Int(pixels[1]) + Int(pixels[2]) + 30)
    }

    func testExportResolutionPNGAndNormalizedComposition() throws {
        let parameters = BloomGeneratorV1.generate(from: try analyzeBytes(Data((0..<256).map(UInt8.init))))
        let preview = try BloomRenderer.render(parameters, pixelSize: 512)
        let full = try BloomRenderer.render(parameters, pixelSize: 2048)
        XCTAssertEqual(full.width, 2048)
        XCTAssertEqual(full.height, 2048)
        let encoded = NSMutableData()
        let destination = try XCTUnwrap(CGImageDestinationCreateWithData(encoded, UTType.png.identifier as CFString, 1, nil))
        CGImageDestinationAddImage(destination, full, nil)
        XCTAssertTrue(CGImageDestinationFinalize(destination))
        let source = try XCTUnwrap(CGImageSourceCreateWithData(encoded, nil))
        let decoded = try XCTUnwrap(CGImageSourceCreateImageAtIndex(source, 0, nil))
        XCTAssertEqual(decoded.width, 2048)
        XCTAssertEqual(decoded.colorSpace?.name, CGColorSpace.sRGB)
        let properties = try XCTUnwrap(CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any])
        // PNG IHDR color type 2 = RGB with no alpha; ImageIO omits HasAlpha for RGB.
        XCTAssertEqual((encoded as Data)[25], 2)
        XCTAssertTrue([CGImageAlphaInfo.none, .noneSkipFirst, .noneSkipLast].contains(decoded.alphaInfo))
        // ImageIO may synthesize pixel dimensions in EXIF. No source metadata is supplied.
        let exif = properties[kCGImagePropertyExifDictionary as String] as? [String: Any] ?? [:]
        XCTAssertEqual(exif[kCGImagePropertyExifColorSpace as String] as? Int, 1)
        XCTAssertTrue(Set(exif.keys).isSubset(of: [kCGImagePropertyExifColorSpace as String,
                                                   kCGImagePropertyExifPixelXDimension as String,
                                                   kCGImagePropertyExifPixelYDimension as String]))
        XCTAssertNil(properties[kCGImagePropertyGPSDictionary as String])
        // Compare low-frequency composition at both resolutions. Raster edges may differ.
        func thumbnail(_ image: CGImage) throws -> [UInt8] {
            let c = try XCTUnwrap(CGContext(data: nil, width: 32, height: 32, bitsPerComponent: 8,
                                           bytesPerRow: 128, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                           bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue))
            c.interpolationQuality = .high
            c.draw(image, in: CGRect(x: 0, y: 0, width: 32, height: 32))
            return Array(UnsafeBufferPointer(start: c.data!.assumingMemoryBound(to: UInt8.self), count: 4096))
        }
        let a = try thumbnail(preview), b = try thumbnail(full)
        let differences = a.indices.filter { $0 % 4 != 3 }.map { abs(Int(a[$0]) - Int(b[$0])) }
        XCTAssertLessThan(Double(differences.reduce(0, +)) / Double(differences.count), 4)
    }

    func testInvalidSizeAndCancellation() async throws {
        let p = BloomGeneratorV1.generate(from: try analyzeBytes(Data([1])))
        XCTAssertThrowsError(try BloomRenderer.render(p, pixelSize: 0))
        XCTAssertThrowsError(try BloomRenderer.render(p, pixelSize: 4096))
        let worker = Task.detached {
            withUnsafeCurrentTask { $0?.cancel() }
            return try BloomRenderer.render(p, pixelSize: 2048)
        }
        do { _ = try await worker.value; XCTFail("Expected cancellation") }
        catch { XCTAssertTrue(error is CancellationError) }
    }

    func testLuminousCoreAtThumbnailSizeAcrossPalettes() throws {
        var checked = Set<Int>()
        for byte in UInt8(0)..<64 {
            let p = BloomGeneratorV1.generate(from: try analyzeBytes(Data([byte])))
            guard checked.insert(p.palette).inserted else { continue }
            let image = try BloomRenderer.render(p, pixelSize: 128)
            let pixels = try XCTUnwrap(image.dataProvider?.data as Data?)
            var core = 0.0, surround = 0.0
            var coreCount = 0, surroundCount = 0
            for y in 0..<128 {
                for x in 0..<128 {
                    let radius = hypot(Double(x) + 0.5 - 64, Double(y) + 0.5 - 64) / 128
                    let offset = y * image.bytesPerRow + x * 4
                    let light = 0.2126 * Double(pixels[offset]) + 0.7152 * Double(pixels[offset + 1])
                        + 0.0722 * Double(pixels[offset + 2])
                    if radius < 0.025 { core += light; coreCount += 1 }
                    if (0.05...0.08).contains(radius) { surround += light; surroundCount += 1 }
                }
            }
            // The compact center must read as a lit focal point, not a dark aperture.
            XCTAssertGreaterThan(core / Double(coreCount), 100, "Palette \(p.palette)")
            XCTAssertGreaterThan(core / Double(coreCount), surround / Double(surroundCount), "Palette \(p.palette)")
        }
        XCTAssertEqual(checked, Set(0..<4))
    }
}
