#!/usr/bin/env swift
import Cocoa

let scriptUrl = URL(fileURLWithPath: #filePath)
let repoRoot = scriptUrl.deletingLastPathComponent().deletingLastPathComponent()
let resourcesDir = repoRoot.appendingPathComponent("Sources/Manageur/Resources").path
let svgPath = "\(resourcesDir)/AppIcon.svg"

try! FileManager.default.createDirectory(atPath: resourcesDir, withIntermediateDirectories: true)

// 1. Load SVG vector
let svgData: Data
if FileManager.default.fileExists(atPath: svgPath), let data = try? Data(contentsOf: URL(fileURLWithPath: svgPath)) {
    svgData = data
} else {
    let fallbackSvg = """
    <?xml version="1.0" encoding="UTF-8"?>
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="1024" height="1024">
      <path d="M0 0h16v16H0z" fill="none" />
      <path fill="#000000" d="M13.854 2.854a.5.5 0 0 0-.708-.708l-4.5 4.5a.5.5 0 0 0 0 .708l4.5 4.5a.5.5 0 0 0 .708-.708L9.707 7zm-11 1.292a.5.5 0 1 0-.708.708L6.293 9l-4.147 4.146a.5.5 0 0 0 .708.708l4.5-4.5a.5.5 0 0 0 0-.708z" />
    </svg>
    """
    svgData = fallbackSvg.data(using: .utf8)!
}

guard let svgImage = NSImage(data: svgData) else {
    fatalError("Failed to load vector SVG")
}

// 2. Exact 72 DPI NSBitmapImageRep rendering function
func renderTransparentPng(pixelSize: Int) -> Data {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixelSize,
        pixelsHigh: pixelSize,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    rep.size = NSSize(width: pixelSize, height: pixelSize)

    let ctx = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = ctx
    let cg = ctx.cgContext

    // 100% transparent background
    cg.clear(CGRect(x: 0, y: 0, width: pixelSize, height: pixelSize))

    // Draw centered vector with standard icon margin (~10% padding on each side)
    let padding = CGFloat(pixelSize) * (100.0 / 1024.0)
    let drawWidth = CGFloat(pixelSize) - (padding * 2.0)
    let drawRect = CGRect(x: padding, y: padding, width: drawWidth, height: drawWidth)
    svgImage.draw(in: drawRect, from: .zero, operation: .sourceOver, fraction: 1.0)

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

// 3. Generate Master 1024x1024 PNG
let masterPng = renderTransparentPng(pixelSize: 1024)
let pngOutputPath = "\(resourcesDir)/AppIcon.png"
try! masterPng.write(to: URL(fileURLWithPath: pngOutputPath))
print("✅ Saved transparent AppIcon.png (1024×1024 at 72 DPI)")

// 4. Generate .iconset directory with all mipmap sizes
let iconsetDir = "/tmp/Manageur.iconset"
try? FileManager.default.removeItem(atPath: iconsetDir)
try! FileManager.default.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

let sizes: [(String, Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for (name, pixelSize) in sizes {
    let png = renderTransparentPng(pixelSize: pixelSize)
    try! png.write(to: URL(fileURLWithPath: "\(iconsetDir)/\(name)"))
}
print("✅ Created transparent iconset with \(sizes.count) image assets")

// 5. Compile with Apple's iconutil into AppIcon.icns
let icnsPath = "\(resourcesDir)/AppIcon.icns"
let iconutilProc = Process()
iconutilProc.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutilProc.arguments = ["-c", "icns", iconsetDir, "-o", icnsPath]
try! iconutilProc.run()
iconutilProc.waitUntilExit()

if iconutilProc.terminationStatus == 0 {
    print("✅ Successfully compiled transparent AppIcon.icns at: \(icnsPath)")
} else {
    fatalError("iconutil failed with exit code \(iconutilProc.terminationStatus)")
}
