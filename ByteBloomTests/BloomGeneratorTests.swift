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
        XCTAssertEqual(p.petals[0].length, 0.3302393574342094, accuracy: 1e-15)
        XCTAssertEqual(p.petals[0].width, 0.11268653232956213, accuracy: 1e-15)
        XCTAssertEqual(p.petals[0].bend, -0.14939864730825891, accuracy: 1e-15)
        XCTAssertEqual(p.petals[0].taper, 0.49803921568627446, accuracy: 1e-15)
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
                XCTAssertTrue((0.09...0.45).contains(petal.length))
                XCTAssertTrue((0.015...0.27).contains(petal.width))
                XCTAssertTrue((-0.255...0.255).contains(petal.bend))
                XCTAssertTrue((5...15).contains(petal.veins))
                XCTAssertTrue((0.16...0.84).contains(petal.taper))
            }
            results.append(p)
        }
        XCTAssertEqual(results[0].filaments.count, 32)
        XCTAssertEqual(results[2].filaments.count, 128)
        XCTAssertLessThan(results[0].growth, results[1].growth)
        XCTAssertNotEqual(results[1].petals, results[2].petals)
        XCTAssertNotEqual(results[1].texture, results[2].texture)
    }

    func testRefinedStructuralVariationAndHistogramTaper() throws {
        let zero = BloomGeneratorV1.generate(from: try analyzeBytes(Data(repeating: 0, count: 65_536)))
        let uniform = BloomGeneratorV1.generate(from: try analyzeBytes(Data((0..<65_536).map { UInt8($0 % 256) })))
        // Independent numerical references: taper = .24 + .42*d[4]/255
        // + .18*histogramMean - .14*sum(p²). Same-size inputs isolate shape from growth.
        XCTAssertEqual(zero.petals[0].taper, 0.2647058823529412, accuracy: 1e-15)
        XCTAssertEqual(uniform.petals[0].taper, 0.4826295955882353, accuracy: 1e-15)
        XCTAssertEqual(zero.growth, uniform.growth)
        let zeroAspect = zero.petals[0].width / zero.petals[0].length
        let uniformAspect = uniform.petals[0].width / uniform.petals[0].length
        XCTAssertGreaterThan(zeroAspect - uniformAspect, 0.05)
        XCTAssertGreaterThan(abs(zero.petals[0].bend - uniform.petals[0].bend), 0.10)
        let zeroLayerRatio = zero.petals[zero.principalPetalCount].length / zero.petals[0].length
        let uniformLayerRatio = uniform.petals[uniform.principalPetalCount].length / uniform.petals[0].length
        XCTAssertGreaterThan(abs(zeroLayerRatio - uniformLayerRatio), 0.05)
    }
}
