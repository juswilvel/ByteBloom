import Foundation

/// Normalized geometry only; no graphics types, source identity, or clock state.
struct BloomParameters: Equatable, Sendable {
    let algorithm = "bloom-v1"
    let palette: Int
    let principalPetalCount: Int
    let orientation: Double
    let growth: Double
    let texture: Double
    let seed: UInt64
    let petals: [Petal]
    let filaments: [Filament]
    let motes: [Mote]

    struct Petal: Equatable, Sendable {
        let layer: Int
        let angle: Double
        let length: Double
        let width: Double
        let bend: Double
        let veins: Int
        let ridge: Double
    }

    struct Filament: Equatable, Sendable {
        let angle: Double
        let length: Double
        let curl: Double
        let light: Double
    }

    struct Mote: Equatable, Sendable {
        let x: Double
        let y: Double
        let radius: Double
        let light: Double
    }
}

/// SplitMix64 (Steele/Vigna): wrapping UInt64 arithmetic, fixed constants.
/// unit() uses the high 53 bits divided by 2^53, yielding [0, 1).
struct SplitMix64 {
    private var state: UInt64
    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9e3779b97f4a7c15
        var z = state
        z = (z ^ (z >> 30)) &* 0xbf58476d1ce4e5b9
        z = (z ^ (z >> 27)) &* 0x94d049bb133111eb
        return z ^ (z >> 31)
    }

    mutating func unit() -> Double { Double(next() >> 11) / 9_007_199_254_740_992 }
}

enum BloomGeneratorV1 {
    /// Candidate v1 contract, pending owner acceptance. Byte indices refer to the
    /// SHA-256 digest in standard displayed order. All multibyte reads are big-endian.
    /// Seed = XOR of the four consecutive 64-bit digest words. PRNG consumption:
    /// each petal: angle, length, width, bend, ridge (5); filament: angle, length,
    /// curl, light (4); mote: angle, radius, size, light (4), in array order.
    static func generate(from analysis: BinaryAnalysis) -> BloomParameters {
        let d = analysis.sha256
        let tau = 2 * Double.pi
        var seed: UInt64 = 0
        for offset in stride(from: 0, to: 32, by: 8) {
            seed ^= d[offset..<(offset + 8)].reduce(UInt64(0)) { ($0 << 8) | UInt64($1) }
        }
        var random = SplitMix64(seed: seed)
        let palette = Int(d[0]) % 4
        let count = 8 + Int(d[1]) % 9
        let orientation = Double(UInt16(d[2]) << 8 | UInt16(d[3])) / 65_536 * tau
        // 1 byte -> 0.787586..., 512 MiB -> 1.0 (clamped logarithmic growth).
        let growth = 0.78 + 0.22 * min(1, log2(Double(analysis.byteCount) + 1) / 29)
        let texture = min(1, max(0, analysis.entropy / 8))
        let frequencies = analysis.histogram.map { Double($0) / Double(analysis.byteCount) }
        let mean = frequencies.enumerated().reduce(0.0) { $0 + Double($1.offset) / 255 * $1.element }
        let concentration = frequencies.reduce(0.0) { $0 + $1 * $1 }
        let bands = (0..<16).map { band in frequencies[(band * 16)..<(band * 16 + 16)].reduce(0, +) }
        var petals: [BloomParameters.Petal] = []
        for layer in 0..<3 {
            for index in 0..<count {
                let band = bands[(index + layer * 5) % 16]
                let angle = orientation + Double(index) / Double(count) * tau
                    + Double(layer) * 0.31 + (random.unit() - 0.5) * 0.065
                let length = [0.385, 0.302, 0.217][layer] * growth * (0.94 + 0.12 * random.unit())
                let width = length * (0.23 + 0.12 * mean + 0.06 * concentration
                    + 0.07 * sqrt(band) + 0.035 * random.unit())
                let bend = (random.unit() - 0.5) * 0.12 + (mean - 0.5) * 0.09
                let ridge = 0.32 + 0.23 * random.unit() + 0.12 * sqrt(band)
                let veins = 5 + Int((6 * sqrt(band) + 4 * texture).rounded(.down))
                petals.append(.init(layer: layer, angle: angle, length: length,
                                    width: width, bend: bend, veins: veins, ridge: ridge))
            }
        }
        let filamentCount = 32 + Int((96 * texture).rounded(.down))
        var filaments: [BloomParameters.Filament] = []
        for index in 0..<filamentCount {
            let angle = orientation + Double(index) / Double(filamentCount) * tau + (random.unit() - 0.5) * 0.07
            let length = growth * (0.28 + 0.13 * random.unit())
            let curl = 0.08 + 0.24 * random.unit()
            let light = 0.25 + 0.55 * random.unit()
            filaments.append(.init(angle: angle, length: length, curl: curl, light: light))
        }
        var motes: [BloomParameters.Mote] = []
        for _ in 0..<(24 + Int(24 * texture)) {
            let angle = random.unit() * tau
            let radius = 0.22 + 0.23 * random.unit()
            let size = 0.0004 + 0.00065 * random.unit()
            let light = 0.12 + 0.24 * random.unit()
            motes.append(.init(x: 0.5 + cos(angle) * radius, y: 0.5 + sin(angle) * radius,
                               radius: size, light: light))
        }
        return BloomParameters(palette: palette, principalPetalCount: count,
                               orientation: orientation, growth: growth, texture: texture,
                               seed: seed, petals: petals, filaments: filaments, motes: motes)
    }
}
