// Run from the repository root: swift Design/MakeIcons.swift
// AppIcon-Master.png is the approved Moonflower blue bloom from bloom-v1.
// Only framing and downsampling are applied. The master remains editable.
import AppKit
import ImageIO
import UniformTypeIdentifiers

let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: "Design/AppIcon-Master.png") as CFURL, nil)!
let master = CGImageSourceCreateImageAtIndex(source, 0, nil)!
let folder = URL(fileURLWithPath: "ByteBloom/Assets.xcassets/AppIcon.appiconset")
func icon(_ size: Int) -> CGImage {
    let c = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: size * 4,
                      space: CGColorSpace(name: CGColorSpace.sRGB)!,
                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    c.scaleBy(x: CGFloat(size), y: CGFloat(size))
    c.addPath(CGPath(roundedRect: CGRect(x: 0.05, y: 0.05, width: 0.90, height: 0.90),
                     cornerWidth: 0.20, cornerHeight: 0.20, transform: nil))
    c.clip()
    c.interpolationQuality = .high
    c.draw(master, in: CGRect(x: 0.015, y: 0.015, width: 0.97, height: 0.97))
    return c.makeImage()!
}
func save(_ image: CGImage, _ url: URL) {
    let d = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(d, image, nil)
    precondition(CGImageDestinationFinalize(d))
}
var images: [[String: String]] = []
for size in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let name = "icon-\(size)@\(scale)x.png"
        save(icon(size * scale), folder.appendingPathComponent(name))
        images.append(["idiom": "mac", "size": "\(size)x\(size)", "scale": "\(scale)x", "filename": name])
    }
}
let contents: [String: Any] = ["images": images, "info": ["author": "xcode", "version": 1]]
try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
    .write(to: folder.appendingPathComponent("Contents.json"))
try FileManager.default.createDirectory(atPath: "/tmp/ByteBloom-0.1.1-review", withIntermediateDirectories: true)
let sheet = NSImage(size: NSSize(width: 920, height: 590))
sheet.lockFocus()
NSColor.windowBackgroundColor.setFill()
NSRect(x: 0, y: 0, width: 920, height: 590).fill()
var x = 20.0
for size in [16, 32, 64, 128, 512] {
    NSImage(cgImage: icon(size), size: NSSize(width: size, height: size))
        .draw(in: NSRect(x: x, y: 50, width: Double(size), height: Double(size)))
    ("\(size) px" as NSString).draw(at: NSPoint(x: x, y: 20),
        withAttributes: [.font: NSFont.systemFont(ofSize: 13), .foregroundColor: NSColor.labelColor])
    x += Double(size) + 28
}
sheet.unlockFocus()
let rep = NSBitmapImageRep(data: sheet.tiffRepresentation!)!
try rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "/tmp/ByteBloom-0.1.1-review/icon-sizes.png"))
