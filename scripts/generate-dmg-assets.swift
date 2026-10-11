import AppKit
import Foundation

guard CommandLine.arguments.count == 2 else {
    fputs("Usage: generate-dmg-assets.swift <output-directory>\n", stderr)
    exit(2)
}

let outputDirectory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
try FileManager.default.createDirectory(
    at: outputDirectory,
    withIntermediateDirectories: true
)

func savePNG(size: NSSize, to url: URL, drawing: () -> Void) throws {
    let image = NSImage(size: size)
    image.lockFocus()
    drawing()
    image.unlockFocus()

    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let data = bitmap.representation(using: .png, properties: [:]) else {
        throw CocoaError(.fileWriteUnknown)
    }
    try data.write(to: url)
}

func drawSpark(center: NSPoint, radius: CGFloat, color: NSColor) {
    let path = NSBezierPath()
    path.move(to: NSPoint(x: center.x, y: center.y + radius))
    path.line(to: NSPoint(x: center.x + radius * 0.22, y: center.y + radius * 0.22))
    path.line(to: NSPoint(x: center.x + radius, y: center.y))
    path.line(to: NSPoint(x: center.x + radius * 0.22, y: center.y - radius * 0.22))
    path.line(to: NSPoint(x: center.x, y: center.y - radius))
    path.line(to: NSPoint(x: center.x - radius * 0.22, y: center.y - radius * 0.22))
    path.line(to: NSPoint(x: center.x - radius, y: center.y))
    path.line(to: NSPoint(x: center.x - radius * 0.22, y: center.y + radius * 0.22))
    path.close()
    color.setFill()
    path.fill()
}

let iconURL = outputDirectory.appendingPathComponent("AppIcon-1024.png")
try savePNG(size: NSSize(width: 1024, height: 1024), to: iconURL) {
    NSColor.clear.setFill()
    NSRect(x: 0, y: 0, width: 1024, height: 1024).fill()

    let tile = NSBezierPath(
        roundedRect: NSRect(x: 72, y: 72, width: 880, height: 880),
        xRadius: 210,
        yRadius: 210
    )
    let gradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.22, green: 0.12, blue: 0.58, alpha: 1),
        NSColor(calibratedRed: 0.42, green: 0.18, blue: 0.86, alpha: 1),
        NSColor(calibratedRed: 0.10, green: 0.55, blue: 0.96, alpha: 1)
    ])!
    gradient.draw(in: tile, angle: -35)

    let bolt = NSBezierPath()
    bolt.move(to: NSPoint(x: 548, y: 790))
    bolt.line(to: NSPoint(x: 322, y: 480))
    bolt.line(to: NSPoint(x: 475, y: 480))
    bolt.line(to: NSPoint(x: 423, y: 226))
    bolt.line(to: NSPoint(x: 700, y: 578))
    bolt.line(to: NSPoint(x: 535, y: 578))
    bolt.close()
    NSColor.white.setFill()
    bolt.fill()

    drawSpark(
        center: NSPoint(x: 742, y: 750),
        radius: 76,
        color: NSColor.white.withAlphaComponent(0.88)
    )
    drawSpark(
        center: NSPoint(x: 245, y: 700),
        radius: 38,
        color: NSColor.white.withAlphaComponent(0.72)
    )
}

let backgroundURL = outputDirectory.appendingPathComponent("dmg-background.png")
try savePNG(size: NSSize(width: 720, height: 440), to: backgroundURL) {
    let bounds = NSRect(x: 0, y: 0, width: 720, height: 440)
    let background = NSGradient(colors: [
        NSColor(calibratedRed: 0.055, green: 0.045, blue: 0.11, alpha: 1),
        NSColor(calibratedRed: 0.09, green: 0.055, blue: 0.20, alpha: 1),
        NSColor(calibratedRed: 0.035, green: 0.11, blue: 0.22, alpha: 1)
    ])!
    background.draw(in: bounds, angle: -20)

    NSColor(calibratedWhite: 1, alpha: 0.045).setFill()
    NSBezierPath(ovalIn: NSRect(x: -110, y: 185, width: 390, height: 390)).fill()
    NSBezierPath(ovalIn: NSRect(x: 520, y: -120, width: 360, height: 360)).fill()

    let centered = NSMutableParagraphStyle()
    centered.alignment = .center

    ("MAC HACKS" as NSString).draw(
        in: NSRect(x: 0, y: 363, width: 720, height: 42),
        withAttributes: [
            .font: NSFont.systemFont(ofSize: 29, weight: .bold),
            .foregroundColor: NSColor.white,
            .paragraphStyle: centered,
            .kern: 1.8
        ]
    )
    ("Hardware tricks, ready to use." as NSString).draw(
        in: NSRect(x: 0, y: 335, width: 720, height: 24),
        withAttributes: [
            .font: NSFont.systemFont(ofSize: 14, weight: .medium),
            .foregroundColor: NSColor.white.withAlphaComponent(0.64),
            .paragraphStyle: centered
        ]
    )

    let arrow = NSBezierPath()
    arrow.lineWidth = 4
    arrow.lineCapStyle = .round
    arrow.lineJoinStyle = .round
    arrow.move(to: NSPoint(x: 300, y: 205))
    arrow.line(to: NSPoint(x: 445, y: 205))
    arrow.move(to: NSPoint(x: 425, y: 225))
    arrow.line(to: NSPoint(x: 447, y: 205))
    arrow.line(to: NSPoint(x: 425, y: 185))
    NSColor(calibratedRed: 0.52, green: 0.68, blue: 1, alpha: 0.9).setStroke()
    arrow.stroke()

    let pillRect = NSRect(x: 297, y: 145, width: 152, height: 30)
    NSColor.white.withAlphaComponent(0.09).setFill()
    NSBezierPath(roundedRect: pillRect, xRadius: 15, yRadius: 15).fill()
    ("DRAG TO INSTALL" as NSString).draw(
        in: NSRect(x: 297, y: 151, width: 152, height: 18),
        withAttributes: [
            .font: NSFont.systemFont(ofSize: 11, weight: .bold),
            .foregroundColor: NSColor.white.withAlphaComponent(0.78),
            .paragraphStyle: centered,
            .kern: 0.8
        ]
    )

    NSColor.white.withAlphaComponent(0.72).setFill()
    NSBezierPath(
        roundedRect: NSRect(x: 115, y: 130, width: 140, height: 30),
        xRadius: 15,
        yRadius: 15
    ).fill()
    NSBezierPath(
        roundedRect: NSRect(x: 465, y: 130, width: 140, height: 30),
        xRadius: 15,
        yRadius: 15
    ).fill()

    ("Drop Mac Hacks into Applications, then launch it from there." as NSString).draw(
        in: NSRect(x: 0, y: 35, width: 720, height: 22),
        withAttributes: [
            .font: NSFont.systemFont(ofSize: 12, weight: .regular),
            .foregroundColor: NSColor.white.withAlphaComponent(0.46),
            .paragraphStyle: centered
        ]
    )
}

print(iconURL.path)
print(backgroundURL.path)
