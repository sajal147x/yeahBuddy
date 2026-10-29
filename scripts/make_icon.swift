import AppKit

// Draws the yeahBuddy app icon: a glowing green dumbbell on a near-black scoreboard
// background. Output is a 1024×1024 PNG with no alpha channel, as App Store Connect requires.
//
// Usage: swift scripts/make_icon.swift yeahBuddy/Assets.xcassets/AppIcon.appiconset/AppIcon.png

let size = 1024
let outPath = CommandLine.arguments[1]

// `noneSkipLast`: 32-bit pixels with the alpha byte ignored, so the PNG has no alpha channel.
let ctx = CGContext(
    data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
    space: CGColorSpace(name: CGColorSpace.sRGB)!,
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
)!

// The app's accent green (matches AccentColor in the asset catalog).
let green = NSColor(srgbRed: 0.188, green: 0.843, blue: 0.231, alpha: 1)
let full = CGRect(x: 0, y: 0, width: size, height: size)

// Background: near-black with a faint green lift in the middle, like the tile glow.
ctx.setFillColor(NSColor(white: 0.04, alpha: 1).cgColor)
ctx.fill(full)
let glow = CGGradient(
    colorsSpace: CGColorSpaceCreateDeviceRGB(),
    colors: [green.withAlphaComponent(0.28).cgColor, green.withAlphaComponent(0).cgColor] as CFArray,
    locations: [0, 1]
)!
ctx.drawRadialGradient(glow, startCenter: CGPoint(x: 512, y: 512), startRadius: 0,
                       endCenter: CGPoint(x: 512, y: 512), endRadius: 520, options: [])

// Dumbbell, built from rounded rectangles and mirrored left/right around the centre.
func rounded(_ rect: CGRect, _ radius: CGFloat) -> CGPath {
    CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
}
let parts: [CGPath] = [
    // Bar across the middle.
    rounded(CGRect(x: 250, y: 474, width: 524, height: 76), 38),
    // Inner (big) plates.
    rounded(CGRect(x: 268, y: 292, width: 108, height: 440), 46),
    rounded(CGRect(x: 648, y: 292, width: 108, height: 440), 46),
    // Outer (small) plates.
    rounded(CGRect(x: 176, y: 372, width: 84, height: 280), 38),
    rounded(CGRect(x: 764, y: 372, width: 84, height: 280), 38),
]

// Soft glow under the dumbbell, then the solid shape on top.
ctx.saveGState()
ctx.setShadow(offset: .zero, blur: 60, color: green.withAlphaComponent(0.9).cgColor)
ctx.setFillColor(green.cgColor)
for part in parts {
    ctx.addPath(part)
    ctx.fillPath()
}
ctx.restoreGState()

let rep = NSBitmapImageRep(cgImage: ctx.makeImage()!)
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: outPath))
print("wrote \(outPath)")
