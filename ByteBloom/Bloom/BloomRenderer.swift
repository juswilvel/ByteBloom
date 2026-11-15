import Foundation
import CoreGraphics

enum BloomRenderError: Error { case invalidSize, allocationFailed }

/// One renderer for preview and export. All geometry, line widths, gradients,
/// and glow radii are expressed in a unit square. Run on a background worker.
/// Pixel encoding/rasterization is not promised identical across OS versions.
enum BloomRenderer {
    static func render(_ parameters: BloomParameters, pixelSize: Int) throws -> CGImage {
        try Task.checkCancellation()
        guard (64...2048).contains(pixelSize) else { throw BloomRenderError.invalidSize }
        guard let space = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(data: nil, width: pixelSize, height: pixelSize,
                                      bitsPerComponent: 8, bytesPerRow: pixelSize * 4,
                                      space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else {
            throw BloomRenderError.allocationFailed
        }
        context.scaleBy(x: Double(pixelSize), y: Double(pixelSize))
        context.setAllowsAntialiasing(true)
        context.setShouldAntialias(true)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        let palette = palettes[parameters.palette]
        context.setFillColor(palette.background.color())
        context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        radial(context, colors: [palette.leaf.color(0.10), palette.background.color(0)],
               center: CGPoint(x: 0.5, y: 0.5), radius: 0.49)

        for mote in parameters.motes {
            context.setFillColor(palette.light.color(mote.light))
            context.fillEllipse(in: CGRect(x: mote.x - mote.radius, y: mote.y - mote.radius,
                                           width: 2 * mote.radius, height: 2 * mote.radius))
        }
        // A quiet outer tracery sits behind the three botanical layers.
        for filament in parameters.filaments {
            try Task.checkCancellation()
            context.saveGState()
            context.translateBy(x: 0.5, y: 0.5)
            context.rotate(by: filament.angle)
            let end = CGPoint(x: filament.curl * filament.length, y: filament.length)
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: 0.045))
            path.addCurve(to: end,
                          control1: CGPoint(x: -0.07, y: filament.length * 0.40),
                          control2: CGPoint(x: filament.curl * filament.length * 1.65, y: filament.length * 0.78))
            stroke(context, path, palette.leaf.color(filament.light * 0.12), 0.0017)
            stroke(context, path, palette.light.color(filament.light * 0.48), 0.00036)
            context.setFillColor(palette.light.color(filament.light * 0.65))
            context.fillEllipse(in: CGRect(x: end.x - 0.0008, y: end.y - 0.0008, width: 0.0016, height: 0.0016))
            context.restoreGState()
        }
        for petal in parameters.petals {
            try Task.checkCancellation()
            drawPetal(context, petal, palette: palette, texture: parameters.texture)
        }
        try drawCenter(context, parameters, palette)
        guard let image = context.makeImage() else { throw BloomRenderError.allocationFailed }
        return image
    }

    private static func drawPetal(_ c: CGContext, _ p: BloomParameters.Petal, palette: Palette, texture: Double) {
        c.saveGState()
        defer { c.restoreGState() }
        c.translateBy(x: 0.5, y: 0.5)
        c.rotate(by: p.angle)
        let length = p.length
        let width = p.width
        let bend = p.bend * length
        let path = petalPath(length: length, width: width, bend: bend)
        let body = p.layer == 1 ? palette.secondary : palette.leaf

        // Translucent lamina, warm at its base, colored through its body, silver at the tip.
        c.saveGState()
        c.addPath(path)
        c.clip()
        linear(c, colors: [palette.background.color(0.94), body.color(0.42),
                           body.color(0.24), palette.light.color(0.17)],
               locations: [0, 0.36, 0.77, 1],
               start: CGPoint(x: 0, y: 0), end: CGPoint(x: bend, y: length))
        linear(c, colors: [body.color(0), body.color(0.12), palette.light.color(0.08), body.color(0)],
               locations: [0, 0.42, 0.51, 1],
               start: CGPoint(x: -width, y: 0), end: CGPoint(x: width, y: 0))

        // Fine nested contour ribs suggest folded, translucent plant tissue.
        for index in 1...7 {
            let fraction = Double(index) / 9
            let rib = CGMutablePath()
            rib.move(to: CGPoint(x: 0, y: 0.022))
            rib.addCurve(to: CGPoint(x: bend, y: length),
                         control1: CGPoint(x: -width * fraction * 0.98, y: length * 0.27),
                         control2: CGPoint(x: -width * fraction * 0.70 + bend, y: length * 0.74))
            stroke(c, rib, palette.light.color(0.06 + 0.035 * texture), 0.00027)
            let other = CGMutablePath()
            other.move(to: CGPoint(x: 0, y: 0.022))
            other.addCurve(to: CGPoint(x: bend, y: length),
                           control1: CGPoint(x: width * fraction, y: length * 0.33),
                           control2: CGPoint(x: width * fraction * 0.48 + bend, y: length * 0.83))
            stroke(c, other, body.color(0.16), 0.00025)
        }
        for index in 1...p.veins {
            let t = 0.17 + Double(index) / Double(p.veins + 1) * 0.69
            let y = length * t
            let spread = width * sin(t * Double.pi) * 0.68
            let spineX = bend * t * t
            for side in [-1.0, 1.0] {
                let branch = CGMutablePath()
                branch.move(to: CGPoint(x: spineX, y: y * 0.79))
                branch.addCurve(to: CGPoint(x: spineX + side * spread, y: y + length * 0.075),
                                control1: CGPoint(x: spineX + side * spread * 0.18, y: y),
                                control2: CGPoint(x: spineX + side * spread * 0.72, y: y + length * 0.018))
                stroke(c, branch, palette.light.color(0.17 + 0.10 * p.ridge), 0.00033)
                // A fine fork breaks up the mechanical appearance of parallel ribs.
                let fork = CGMutablePath()
                fork.move(to: CGPoint(x: spineX + side * spread * 0.52, y: y + length * 0.018))
                fork.addQuadCurve(to: CGPoint(x: spineX + side * spread * 0.91, y: y + length * 0.13),
                                  control: CGPoint(x: spineX + side * spread * 0.64, y: y + length * 0.08))
                stroke(c, fork, body.color(0.22), 0.00025)
            }
        }
        c.restoreGState()

        stroke(c, path, body.color(0.10), 0.0027)
        stroke(c, path, palette.light.color(0.35 + Double(p.layer) * 0.07), 0.00055)
        // Highlight one edge, stopping short of a uniform neon outline.
        let edge = CGMutablePath()
        edge.move(to: CGPoint(x: 0, y: 0.025))
        edge.addCurve(to: CGPoint(x: bend, y: length),
                      control1: CGPoint(x: -width * 1.05, y: length * 0.36),
                      control2: CGPoint(x: -width * 0.50 + bend, y: length * 0.83))
        stroke(c, edge, body.color(0.46), 0.0008)
        let spine = CGMutablePath()
        spine.move(to: CGPoint(x: 0, y: 0.026))
        spine.addCurve(to: CGPoint(x: bend, y: length * 0.97),
                       control1: CGPoint(x: -bend * 0.5, y: length * p.ridge),
                       control2: CGPoint(x: bend * 0.3, y: length * 0.73))
        stroke(c, spine, palette.light.color(0.18), 0.0018)
        stroke(c, spine, palette.light.color(0.68), 0.00045)
    }

    private static func petalPath(length: Double, width: Double, bend: Double) -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 0.025))
        path.addCurve(to: CGPoint(x: bend, y: length),
                      control1: CGPoint(x: -width * 1.05, y: length * 0.36),
                      control2: CGPoint(x: -width * 0.50 + bend, y: length * 0.83))
        path.addCurve(to: CGPoint(x: 0, y: 0.025),
                      control1: CGPoint(x: width * 0.30 + bend, y: length * 0.85),
                      control2: CGPoint(x: width * 1.24, y: length * 0.41))
        path.closeSubpath()
        return path
    }

    private static func drawCenter(_ c: CGContext, _ p: BloomParameters, _ palette: Palette) throws {
        let center = CGPoint(x: 0.5, y: 0.5)
        radial(c, colors: [palette.gold.color(0.20), palette.gold.color(0)], center: center, radius: 0.105)
        // Golden-angle phyllotaxis: a seed head, not a stack of concentric circles.
        for index in (0..<181).reversed() {
            if index % 24 == 0 { try Task.checkCancellation() }
            let t = Double(index) / 180
            let angle = Double(index) * 2.399963229728653 + p.orientation
            let radius = 0.052 * sqrt(t) * p.growth
            let x = 0.5 + cos(angle) * radius
            let y = 0.5 + sin(angle) * radius
            let size = 0.00115 + 0.0010 * t
            c.saveGState()
            c.translateBy(x: x, y: y)
            c.rotate(by: angle + 0.5)
            let seed = CGRect(x: -size * 0.62, y: -size, width: size * 1.24, height: size * 2.3)
            c.setFillColor(palette.background.color(0.90))
            c.fillEllipse(in: seed.insetBy(dx: -0.0005, dy: -0.0005))
            c.setFillColor(palette.gold.color(0.45 + 0.43 * (1 - t)))
            c.fillEllipse(in: seed)
            c.setStrokeColor(palette.light.color(0.55))
            c.setLineWidth(0.0003)
            c.strokeEllipse(in: seed)
            c.setFillColor(palette.light.color(0.80))
            c.fillEllipse(in: CGRect(x: -0.00045, y: size * 0.45, width: 0.0009, height: 0.0009))
            c.restoreGState()
        }
    }

    private static func stroke(_ c: CGContext, _ path: CGPath, _ color: CGColor, _ width: Double) {
        c.addPath(path)
        c.setStrokeColor(color)
        c.setLineWidth(width)
        c.strokePath()
    }

    private static func linear(_ c: CGContext, colors: [CGColor], locations: [CGFloat], start: CGPoint, end: CGPoint) {
        guard let gradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
                                        colors: colors as CFArray, locations: locations) else { return }
        c.drawLinearGradient(gradient, start: start, end: end, options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
    }

    private static func radial(_ c: CGContext, colors: [CGColor], center: CGPoint, radius: Double) {
        guard let gradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
                                        colors: colors as CFArray, locations: [0, 1]) else { return }
        c.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: radius, options: [])
    }

    struct RGB: Sendable {
        let hex: UInt32
        func color(_ alpha: Double = 1) -> CGColor {
            CGColor(srgbRed: Double((hex >> 16) & 255) / 255,
                    green: Double((hex >> 8) & 255) / 255,
                    blue: Double(hex & 255) / 255, alpha: alpha)
        }
    }

    struct Palette: Sendable {
        let name: String
        let background: RGB
        let leaf: RGB
        let secondary: RGB
        let light: RGB
        let gold: RGB
    }

    static let palettes: [Palette] = [
        .init(name: "Jade & champagne", background: RGB(hex: 0x060f16), leaf: RGB(hex: 0x53c9b3),
              secondary: RGB(hex: 0x297e91), light: RGB(hex: 0xc4ead8), gold: RGB(hex: 0xe6bd7b)),
        .init(name: "Iris & antique gold", background: RGB(hex: 0x0c0b1a), leaf: RGB(hex: 0xa38bd2),
              secondary: RGB(hex: 0x586bb4), light: RGB(hex: 0xe4d8ee), gold: RGB(hex: 0xdcb978)),
        .init(name: "Rose & sea glass", background: RGB(hex: 0x120c16), leaf: RGB(hex: 0xd08b9e),
              secondary: RGB(hex: 0x68a9ac), light: RGB(hex: 0xf3d9ca), gold: RGB(hex: 0xe7b788)),
        .init(name: "Moonflower blue", background: RGB(hex: 0x080f1c), leaf: RGB(hex: 0x6ca9d5),
              secondary: RGB(hex: 0x6580b7), light: RGB(hex: 0xd8e9ed), gold: RGB(hex: 0xc7d8c3))
    ]
}
