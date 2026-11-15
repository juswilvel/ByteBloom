import XCTest
@testable import ByteBloom

final class BloomGeneratorTests: XCTestCase {
    func testSplitMix64ReferenceSequence() {
        var rng = SplitMix64(seed: 0)
        XCTAssertEqual(rng.next(), 0xe220a8397b1dcdaf)
        XCTAssertEqual(rng.next(), 0x6e789e6aa1b965f4)
        XCTAssertEqual(rng.next(), 0x06c45d188009454f)
    }

    func testGoldenABC() throws {
        let p = BloomGeneratorV1.generate(from: try analyzeBytes(Data("abc".utf8)))
        XCTAssertEqual(p.algorithm, "bloom-v1")
        XCTAssertEqual(p.palette, 2)
        XCTAssertEqual(p.principalPetalCount, 11)
        // Independently calculated with the documented big-endian XOR seed contract.
        XCTAssertEqual(p.seed, 0xff2ac8a3b6b882f8)
        XCTAssertEqual(p.orientation, 0.5582731329911306, accuracy: 1e-15)
        XCTAssertEqual(p.petals[0].angle, 0.5894244921507991, accuracy: 1e-15)
        XCTAssertEqual(p.petals[0].length, 0.30451321956407335, accuracy: 1e-15)
        XCTAssertEqual(p.petals[0].width, 0.09292030009442638, accuracy: 1e-15)
        XCTAssertEqual(p.petals[0].bend, 0.0073312153536940015, accuracy: 1e-15)
        XCTAssertEqual(p.petals[0].ridge, 0.44615275613816546, accuracy: 1e-15)
        XCTAssertEqual(p.petals.count, 33)
        XCTAssertEqual(p.filaments.count, 51)
        XCTAssertEqual(p.growth, 0.7951724137931034, accuracy: 1e-15)
        XCTAssertEqual(p.texture, log2(3) / 8, accuracy: 1e-15)
    }

    func testRepeatabilityAndSafeBounds() throws {
        let fixtures = [Data([0]), Data(repeating: 0, count: 65_536),
                        Data((0..<65_536).map { UInt8($0 % 256) }),
                        Data(String(repeating: "Every file has a hidden beauty.\n", count: 800).utf8)]
        var results: [BloomParameters] = []
        for fixture in fixtures {
            let p = BloomGeneratorV1.generate(from: try analyzeBytes(fixture))
            XCTAssertEqual(p, BloomGeneratorV1.generate(from: try analyzeBytes(fixture, chunkSize: 17)))
            XCTAssertTrue((0...3).contains(p.palette))
            XCTAssertTrue((8...16).contains(p.principalPetalCount))
            XCTAssertEqual(p.petals.count, 3 * p.principalPetalCount)
            XCTAssertTrue((32...128).contains(p.filaments.count))
            XCTAssertTrue((0.78...1).contains(p.growth))
            for petal in p.petals {
                XCTAssertTrue(petal.angle.isFinite)
                XCTAssertTrue((0.15...0.41).contains(petal.length))
                XCTAssertTrue((0.03...0.20).contains(petal.width))
                XCTAssertTrue((-0.11...0.11).contains(petal.bend))
                XCTAssertTrue((5...15).contains(petal.veins))
            }
            results.append(p)
        }
        XCTAssertEqual(results[0].filaments.count, 32)
        XCTAssertEqual(results[2].filaments.count, 128)
        XCTAssertLessThan(results[0].growth, results[1].growth)
        XCTAssertNotEqual(results[1].petals, results[2].petals)
        XCTAssertNotEqual(results[1].texture, results[2].texture)
    }
}
