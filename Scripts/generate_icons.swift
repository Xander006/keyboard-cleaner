import AppKit

let fileManager = FileManager.default
let projectRoot = URL(fileURLWithPath: fileManager.currentDirectoryPath)
let appIconSetURL = projectRoot.appendingPathComponent("KeyboardCleaner/Assets.xcassets/AppIcon.appiconset")
let menuBarIconSetURL = projectRoot.appendingPathComponent("KeyboardCleaner/Assets.xcassets/MenuBarIcon.imageset")
let previewURL = projectRoot.appendingPathComponent("icon_preview_v2.png")

struct Palette {
    static let shellTop = NSColor(calibratedRed: 0.73, green: 0.80, blue: 0.87, alpha: 1)
    static let shellBottom = NSColor(calibratedRed: 0.30, green: 0.36, blue: 0.45, alpha: 1)
    static let shellEdge = NSColor(calibratedRed: 0.92, green: 0.95, blue: 0.98, alpha: 1)
    static let shellMist = NSColor(calibratedWhite: 1.0, alpha: 0.94)
    static let keyTop = NSColor(calibratedRed: 0.995, green: 0.997, blue: 1.0, alpha: 1)
    static let keyBottom = NSColor(calibratedRed: 0.90, green: 0.93, blue: 0.97, alpha: 1)
    static let keyEdge = NSColor(calibratedRed: 0.82, green: 0.87, blue: 0.92, alpha: 1)
    static let baseTop = NSColor(calibratedRed: 0.66, green: 0.72, blue: 0.79, alpha: 0.98)
    static let baseBottom = NSColor(calibratedRed: 0.47, green: 0.53, blue: 0.61, alpha: 0.99)
    static let glyph = NSColor(calibratedRed: 0.31, green: 0.35, blue: 0.40, alpha: 0.96)
    static let accentBlue = NSColor(calibratedRed: 0.60, green: 0.79, blue: 0.96, alpha: 1)
    static let accentSoft = NSColor(calibratedRed: 0.90, green: 0.96, blue: 1.0, alpha: 1)
}

func roundedRectPath(_ rect: NSRect, radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
}

func fillLinearGradient(in path: NSBezierPath, colors: [NSColor], angle: CGFloat) {
    let gradient = NSGradient(colors: colors)!
    gradient.draw(in: path, angle: angle)
}

func drawGlow(in rect: NSRect, color: NSColor, alpha: CGFloat) {
    let glowPath = NSBezierPath(ovalIn: rect)
    color.withAlphaComponent(alpha).setFill()
    glowPath.fill()
}

func drawSparkle(center: CGPoint, radius: CGFloat, color: NSColor) {
    let sparkle = NSBezierPath()
    sparkle.lineWidth = max(1, radius * 0.28)
    sparkle.lineCapStyle = .round
    sparkle.move(to: CGPoint(x: center.x, y: center.y + radius))
    sparkle.line(to: CGPoint(x: center.x, y: center.y - radius))
    sparkle.move(to: CGPoint(x: center.x - radius, y: center.y))
    sparkle.line(to: CGPoint(x: center.x + radius, y: center.y))
    color.setStroke()
    sparkle.stroke()
}

func savePNG(image: NSImage, to url: URL) throws {
    guard
        let tiff = image.tiffRepresentation,
        let rep = NSBitmapImageRep(data: tiff),
        let data = rep.representation(using: .png, properties: [:])
    else {
        throw NSError(domain: "IconGeneration", code: 1)
    }
    try data.write(to: url)
}

func drawAppIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    defer { image.unlockFocus() }

    NSGraphicsContext.current?.imageInterpolation = .high

    let canvas = NSRect(x: 0, y: 0, width: size, height: size)
    let iconRect = canvas.insetBy(dx: size * 0.04, dy: size * 0.04)
    let iconRadius = size * 0.225

    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.20)
    shadow.shadowBlurRadius = size * 0.06
    shadow.shadowOffset = NSSize(width: 0, height: -size * 0.024)
    shadow.set()

    let iconPath = roundedRectPath(iconRect, radius: iconRadius)
    fillLinearGradient(in: iconPath, colors: [Palette.shellTop, Palette.shellBottom], angle: -90)

    NSGraphicsContext.current?.saveGraphicsState()
    iconPath.addClip()

    drawGlow(
        in: NSRect(x: size * 0.08, y: size * 0.64, width: size * 0.84, height: size * 0.20),
        color: Palette.shellMist,
        alpha: 0.18
    )
    drawGlow(
        in: NSRect(x: size * 0.24, y: size * 0.20, width: size * 0.52, height: size * 0.22),
        color: Palette.accentBlue,
        alpha: 0.08
    )

    let glossPath = roundedRectPath(
        NSRect(x: iconRect.minX, y: iconRect.midY + size * 0.05, width: iconRect.width, height: iconRect.height * 0.34),
        radius: iconRadius
    )
    let gloss = NSGradient(colors: [
        NSColor.white.withAlphaComponent(0.24),
        NSColor.white.withAlphaComponent(0.04),
        .clear,
    ])!
    gloss.draw(in: glossPath, angle: 90)

    let plateWidth = size * 0.58
    let plateHeight = size * 0.42
    let plateRect = NSRect(
        x: (size - plateWidth) / 2,
        y: size * 0.24,
        width: plateWidth,
        height: plateHeight
    )
    let platePath = roundedRectPath(plateRect, radius: size * 0.15)
    let plateGradient = NSGradient(colors: [
        NSColor.white.withAlphaComponent(0.10),
        NSColor.white.withAlphaComponent(0.04),
        NSColor.clear,
    ])!
    plateGradient.draw(in: platePath, angle: 90)

    let keyWidth = size * 0.48
    let keyHeight = size * 0.34
    let keyRect = NSRect(
        x: (size - keyWidth) / 2,
        y: size * 0.29,
        width: keyWidth,
        height: keyHeight
    )
    let keyBaseRect = keyRect.offsetBy(dx: 0, dy: -size * 0.040)

    let baseShadow = NSShadow()
    baseShadow.shadowColor = NSColor.black.withAlphaComponent(0.16)
    baseShadow.shadowBlurRadius = size * 0.036
    baseShadow.shadowOffset = NSSize(width: 0, height: -size * 0.018)
    baseShadow.set()

    let keyBasePath = roundedRectPath(keyBaseRect, radius: size * 0.09)
    fillLinearGradient(
        in: keyBasePath,
        colors: [
            Palette.baseTop,
            Palette.baseBottom,
        ],
        angle: -90
    )

    NSShadow().set()

    let keyFacePath = roundedRectPath(keyRect, radius: size * 0.09)
    fillLinearGradient(in: keyFacePath, colors: [Palette.keyTop, Palette.keyBottom], angle: -90)

    let keyEdgePath = roundedRectPath(keyRect.insetBy(dx: size * 0.003, dy: size * 0.003), radius: size * 0.086)
    Palette.keyEdge.withAlphaComponent(0.34).setStroke()
    keyEdgePath.lineWidth = max(1.2, size * 0.004)
    keyEdgePath.stroke()

    let innerHighlight = roundedRectPath(keyRect.insetBy(dx: size * 0.008, dy: size * 0.008), radius: size * 0.08)
    NSColor.white.withAlphaComponent(0.38).setStroke()
    innerHighlight.lineWidth = max(1.5, size * 0.006)
    innerHighlight.stroke()

    let topPlane = roundedRectPath(
        NSRect(
            x: keyRect.minX + size * 0.012,
            y: keyRect.midY + size * 0.012,
            width: keyRect.width - size * 0.024,
            height: keyRect.height * 0.44
        ),
        radius: size * 0.055
    )
    let topGradient = NSGradient(colors: [
        NSColor.white.withAlphaComponent(0.34),
        NSColor.white.withAlphaComponent(0.08),
        NSColor.clear,
    ])!
    topGradient.draw(in: topPlane, angle: 90)

    let wipePath = NSBezierPath()
    wipePath.lineWidth = size * 0.028
    wipePath.lineCapStyle = .round
    wipePath.move(to: CGPoint(x: keyRect.minX + keyRect.width * 0.22, y: keyRect.minY + keyRect.height * 0.63))
    wipePath.curve(
        to: CGPoint(x: keyRect.maxX - keyRect.width * 0.18, y: keyRect.minY + keyRect.height * 0.44),
        controlPoint1: CGPoint(x: keyRect.midX - keyRect.width * 0.12, y: keyRect.maxY - keyRect.height * 0.02),
        controlPoint2: CGPoint(x: keyRect.maxX - keyRect.width * 0.30, y: keyRect.midY + keyRect.height * 0.08)
    )
    Palette.accentBlue.withAlphaComponent(0.34).setStroke()
    wipePath.stroke()

    let wipeGlowPath = NSBezierPath()
    wipeGlowPath.lineWidth = size * 0.010
    wipeGlowPath.lineCapStyle = .round
    wipeGlowPath.move(to: CGPoint(x: keyRect.minX + keyRect.width * 0.24, y: keyRect.minY + keyRect.height * 0.64))
    wipeGlowPath.curve(
        to: CGPoint(x: keyRect.maxX - keyRect.width * 0.20, y: keyRect.minY + keyRect.height * 0.47),
        controlPoint1: CGPoint(x: keyRect.midX - keyRect.width * 0.11, y: keyRect.maxY - keyRect.height * 0.07),
        controlPoint2: CGPoint(x: keyRect.maxX - keyRect.width * 0.29, y: keyRect.midY + keyRect.height * 0.10)
    )
    NSColor.white.withAlphaComponent(0.34).setStroke()
    wipeGlowPath.stroke()

    let groovePath = NSBezierPath()
    groovePath.lineWidth = max(2, size * 0.016)
    groovePath.lineCapStyle = .round
    groovePath.move(to: CGPoint(x: keyRect.minX + keyRect.width * 0.26, y: keyRect.minY + keyRect.height * 0.20))
    groovePath.line(to: CGPoint(x: keyRect.maxX - keyRect.width * 0.26, y: keyRect.minY + keyRect.height * 0.20))
    Palette.glyph.withAlphaComponent(0.14).setStroke()
    groovePath.stroke()

    let lockBodyRect = NSRect(
        x: keyRect.midX - size * 0.045,
        y: keyRect.midY + size * 0.002,
        width: size * 0.090,
        height: size * 0.068
    )
    let lockBodyPath = roundedRectPath(lockBodyRect, radius: size * 0.021)
    fillLinearGradient(
        in: lockBodyPath,
        colors: [Palette.glyph.withAlphaComponent(0.94), Palette.glyph.withAlphaComponent(0.76)],
        angle: -90
    )

    let shacklePath = NSBezierPath()
    shacklePath.lineWidth = max(2, size * 0.012)
    shacklePath.lineCapStyle = .round
    shacklePath.move(to: CGPoint(x: lockBodyRect.minX + size * 0.016, y: lockBodyRect.maxY - size * 0.002))
    shacklePath.curve(
        to: CGPoint(x: lockBodyRect.maxX - size * 0.016, y: lockBodyRect.maxY - size * 0.002),
        controlPoint1: CGPoint(x: lockBodyRect.minX + size * 0.004, y: lockBodyRect.maxY + size * 0.044),
        controlPoint2: CGPoint(x: lockBodyRect.maxX - size * 0.004, y: lockBodyRect.maxY + size * 0.044)
    )
    Palette.glyph.withAlphaComponent(0.78).setStroke()
    shacklePath.stroke()

    let keyhole = NSBezierPath(ovalIn: NSRect(
        x: lockBodyRect.midX - size * 0.007,
        y: lockBodyRect.minY + size * 0.017,
        width: size * 0.014,
        height: size * 0.018
    ))
    NSColor.white.withAlphaComponent(0.30).setFill()
    keyhole.fill()

    drawSparkle(center: CGPoint(x: size * 0.75, y: size * 0.70), radius: size * 0.022, color: NSColor.white.withAlphaComponent(0.94))

    let edgePath = roundedRectPath(iconRect.insetBy(dx: size * 0.004, dy: size * 0.004), radius: iconRadius * 0.96)
    let edgeGradient = NSGradient(colors: [
        Palette.shellEdge.withAlphaComponent(0.30),
        Palette.accentSoft.withAlphaComponent(0.06),
        NSColor.black.withAlphaComponent(0.14),
    ])!
    edgeGradient.draw(in: edgePath, angle: -62)

    NSGraphicsContext.current?.restoreGraphicsState()

    return image
}

func drawMenuBarIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    defer { image.unlockFocus() }

    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    let keyRect = rect.insetBy(dx: size * 0.19, dy: size * 0.22)
    let path = roundedRectPath(keyRect, radius: size * 0.18)
    NSColor.black.setStroke()
    path.lineWidth = max(1.2, size * 0.11)
    path.stroke()

    let wipe = NSBezierPath()
    wipe.lineWidth = max(1.0, size * 0.075)
    wipe.lineCapStyle = .round
    wipe.move(to: CGPoint(x: keyRect.minX + size * 0.12, y: keyRect.midY + size * 0.06))
    wipe.line(to: CGPoint(x: keyRect.maxX - size * 0.12, y: keyRect.midY - size * 0.03))
    wipe.stroke()

    let sparkle = NSBezierPath()
    let s = size * 0.08
    let c = CGPoint(x: rect.maxX - size * 0.22, y: rect.maxY - size * 0.24)
    sparkle.lineWidth = max(1, size * 0.08)
    sparkle.lineCapStyle = .round
    sparkle.move(to: CGPoint(x: c.x, y: c.y + s))
    sparkle.line(to: CGPoint(x: c.x, y: c.y - s))
    sparkle.move(to: CGPoint(x: c.x - s, y: c.y))
    sparkle.line(to: CGPoint(x: c.x + s, y: c.y))
    NSColor.black.setStroke()
    sparkle.stroke()

    return image
}

try fileManager.createDirectory(at: menuBarIconSetURL, withIntermediateDirectories: true)

let appSizes: [(Int, String)] = [
    (16, "icon_16x16.png"),
    (32, "icon_16x16@2x.png"),
    (32, "icon_32x32.png"),
    (64, "icon_32x32@2x.png"),
    (128, "icon_128x128.png"),
    (256, "icon_128x128@2x.png"),
    (256, "icon_256x256.png"),
    (512, "icon_256x256@2x.png"),
    (512, "icon_512x512.png"),
    (1024, "icon_512x512@2x.png"),
]

for (size, fileName) in appSizes {
    let image = drawAppIcon(size: CGFloat(size))
    try savePNG(image: image, to: appIconSetURL.appendingPathComponent(fileName))
}

try savePNG(image: drawAppIcon(size: 1024), to: previewURL)
try savePNG(image: drawMenuBarIcon(size: 18), to: menuBarIconSetURL.appendingPathComponent("menubar.png"))
try savePNG(image: drawMenuBarIcon(size: 36), to: menuBarIconSetURL.appendingPathComponent("menubar@2x.png"))
