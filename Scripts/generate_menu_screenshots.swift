import AppKit

struct MenuItem {
    let title: String
    let shortcut: String?
    let submenu: Bool
    let destructive: Bool

    init(_ title: String, shortcut: String? = nil, submenu: Bool = false, destructive: Bool = false) {
        self.title = title
        self.shortcut = shortcut
        self.submenu = submenu
        self.destructive = destructive
    }
}

enum MenuRow {
    case item(MenuItem)
    case divider
}

struct MenuPanel {
    let rows: [MenuRow]
    let highlightedRow: Int?
}

let appIconPath = NSString(string: "/Users/alex/Keyboard Lock/KeyboardCleaner/Assets.xcassets/AppIcon.appiconset/icon_512x512@2x.png")
let outputDir = NSString(string: "/Users/alex/Keyboard Lock/generated-menu-shots")

let mainMenu = MenuPanel(
    rows: [
        .item(MenuItem("Lock Keyboard")),
        .item(MenuItem("Presets", submenu: true)),
        .divider,
        .item(MenuItem("Open", submenu: true)),
        .divider,
        .item(MenuItem("Quit Keyboard Cleaner"))
    ],
    highlightedRow: nil
)

let presetsMenu = MenuPanel(
    rows: [
        .item(MenuItem("Quick Wipe")),
        .item(MenuItem("Focused Desk")),
        .item(MenuItem("Deep Clean"))
    ],
    highlightedRow: nil
)

let openMenu = MenuPanel(
    rows: [
        .item(MenuItem("Settings…")),
        .item(MenuItem("Diagnostics…")),
        .item(MenuItem("Help…"))
    ],
    highlightedRow: nil
)

try FileManager.default.createDirectory(
    atPath: outputDir as String,
    withIntermediateDirectories: true
)

renderScene(
    filename: "keyboardcleaner-menu-main.png",
    mainPanel: mainMenu,
    submenu: nil
)

renderScene(
    filename: "keyboardcleaner-menu-presets.png",
    mainPanel: MenuPanel(rows: mainMenu.rows, highlightedRow: 1),
    submenu: presetsMenu
)

renderScene(
    filename: "keyboardcleaner-menu-open.png",
    mainPanel: MenuPanel(rows: mainMenu.rows, highlightedRow: 3),
    submenu: openMenu
)

func renderScene(filename: String, mainPanel: MenuPanel, submenu: MenuPanel?) {
    let canvasSize = NSSize(width: 1080, height: 900)
    let image = NSImage(size: canvasSize)
    image.lockFocus()

    let context = NSGraphicsContext.current!.cgContext
    context.setFillColor(NSColor(calibratedRed: 0.94, green: 0.95, blue: 0.97, alpha: 1).cgColor)
    context.fill(CGRect(origin: .zero, size: canvasSize))

    drawDesktopBackdrop(in: context, size: canvasSize)
    drawMenuBar(in: context, size: canvasSize)

    let mainOrigin = CGPoint(x: 760, y: 400)
    let mainSize = drawMenuPanel(mainPanel, at: mainOrigin, minWidth: 248)

    if let submenu {
        let submenuOrigin = CGPoint(x: mainOrigin.x + mainSize.width - 12, y: mainOrigin.y + 10)
        _ = drawMenuPanel(submenu, at: submenuOrigin, minWidth: 224)
    }

    image.unlockFocus()

    guard
        let tiffData = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiffData),
        let pngData = bitmap.representation(using: .png, properties: [:])
    else {
        fputs("Failed to encode \(filename)\n", stderr)
        exit(1)
    }

    let destination = URL(fileURLWithPath: (outputDir as String)).appendingPathComponent(filename)
    try? pngData.write(to: destination)
    print(destination.path)
}

func drawDesktopBackdrop(in context: CGContext, size: NSSize) {
    let gradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.79, green: 0.88, blue: 0.97, alpha: 1),
        NSColor(calibratedRed: 0.96, green: 0.98, blue: 1.00, alpha: 1)
    ])!
    gradient.draw(in: NSRect(origin: .zero, size: size), angle: 90)

    context.setFillColor(NSColor(calibratedRed: 0.47, green: 0.74, blue: 0.91, alpha: 0.28).cgColor)
    context.fillEllipse(in: CGRect(x: 40, y: 80, width: 420, height: 300))

    context.setFillColor(NSColor(calibratedRed: 0.76, green: 0.84, blue: 0.99, alpha: 0.30).cgColor)
    context.fillEllipse(in: CGRect(x: 300, y: 300, width: 520, height: 360))

    context.setFillColor(NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 0.18).cgColor)
    context.fillEllipse(in: CGRect(x: 180, y: 520, width: 640, height: 240))
}

func drawMenuBar(in context: CGContext, size: NSSize) {
    let barRect = CGRect(x: 0, y: size.height - 52, width: size.width, height: 52)
    let barPath = NSBezierPath(roundedRect: barRect, xRadius: 0, yRadius: 0)
    NSColor(calibratedWhite: 1, alpha: 0.78).setFill()
    barPath.fill()

    context.setFillColor(NSColor(calibratedWhite: 1, alpha: 0.65).cgColor)
    context.fill(CGRect(x: 0, y: size.height - 53, width: size.width, height: 1))

    let titleAttrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 17, weight: .semibold),
        .foregroundColor: NSColor(calibratedWhite: 0.12, alpha: 0.9)
    ]
    NSAttributedString(string: "Mon 6 Apr  16:04", attributes: titleAttrs)
        .draw(at: CGPoint(x: 40, y: size.height - 36))

    let iconRect = CGRect(x: size.width - 128, y: size.height - 43, width: 30, height: 30)
    let capsuleRect = iconRect.insetBy(dx: -10, dy: -2)
    let capsule = NSBezierPath(roundedRect: capsuleRect, xRadius: 10, yRadius: 10)
    NSColor(calibratedRed: 0.16, green: 0.52, blue: 0.98, alpha: 0.92).setFill()
    capsule.fill()

    if let icon = NSImage(contentsOfFile: appIconPath as String) {
        icon.draw(in: iconRect)
    }
}

@discardableResult
func drawMenuPanel(_ panel: MenuPanel, at topLeft: CGPoint, minWidth: CGFloat) -> CGSize {
    let rowHeight: CGFloat = 34
    let dividerHeight: CGFloat = 11
    let paddingX: CGFloat = 14
    let paddingY: CGFloat = 10

    let itemFont = NSFont.systemFont(ofSize: 14, weight: .regular)
    let shortcutFont = NSFont.systemFont(ofSize: 13, weight: .regular)

    var textWidth = minWidth - (paddingX * 2)
    for row in panel.rows {
        guard case let .item(item) = row else { continue }
        textWidth = max(textWidth, item.title.size(withAttributes: [.font: itemFont]).width + 54)
        if let shortcut = item.shortcut {
            textWidth += shortcut.size(withAttributes: [.font: shortcutFont]).width
        }
    }

    let contentHeight = panel.rows.reduce(CGFloat(0)) { partial, row in
        partial + (row.isDivider ? dividerHeight : rowHeight)
    }
    let panelSize = CGSize(width: textWidth + paddingX * 2, height: contentHeight + paddingY * 2)
    let panelRect = CGRect(x: topLeft.x, y: topLeft.y, width: panelSize.width, height: panelSize.height)

    let shadow = NSShadow()
    shadow.shadowBlurRadius = 18
    shadow.shadowOffset = NSSize(width: 0, height: -4)
    shadow.shadowColor = NSColor(calibratedWhite: 0.1, alpha: 0.22)
    shadow.set()

    let backgroundPath = NSBezierPath(roundedRect: panelRect, xRadius: 14, yRadius: 14)
    NSColor(calibratedWhite: 1.0, alpha: 0.96).setFill()
    backgroundPath.fill()

    NSGraphicsContext.current?.saveGraphicsState()
    backgroundPath.addClip()

    var currentY = panelRect.maxY - paddingY
    var itemIndex = 0

    for row in panel.rows {
        switch row {
        case .divider:
            currentY -= dividerHeight
            let lineRect = CGRect(
                x: panelRect.minX + 12,
                y: currentY + (dividerHeight / 2),
                width: panelRect.width - 24,
                height: 1
            )
            NSColor(calibratedWhite: 0.84, alpha: 1).setFill()
            NSBezierPath(rect: lineRect).fill()
        case let .item(item):
            currentY -= rowHeight
            let rowRect = CGRect(
                x: panelRect.minX + 6,
                y: currentY + 1,
                width: panelRect.width - 12,
                height: rowHeight - 2
            )

            let isHighlighted = panel.highlightedRow == itemIndex
            if isHighlighted {
                let highlightPath = NSBezierPath(roundedRect: rowRect, xRadius: 9, yRadius: 9)
                NSColor(calibratedRed: 0.12, green: 0.49, blue: 0.96, alpha: 1).setFill()
                highlightPath.fill()
            }

            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: itemFont,
                .foregroundColor: isHighlighted ? NSColor.white : NSColor(calibratedWhite: item.destructive ? 0.18 : 0.12, alpha: 1)
            ]
            NSAttributedString(string: item.title, attributes: titleAttrs)
                .draw(at: CGPoint(x: rowRect.minX + 12, y: rowRect.minY + 8))

            if let shortcut = item.shortcut {
                let shortcutAttrs: [NSAttributedString.Key: Any] = [
                    .font: shortcutFont,
                    .foregroundColor: isHighlighted ? NSColor.white.withAlphaComponent(0.88) : NSColor(calibratedWhite: 0.45, alpha: 1)
                ]
                let width = shortcut.size(withAttributes: shortcutAttrs).width
                NSAttributedString(string: shortcut, attributes: shortcutAttrs)
                    .draw(at: CGPoint(x: rowRect.maxX - width - 14, y: rowRect.minY + 9))
            }

            if item.submenu {
                let arrowAttrs: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 15, weight: .medium),
                    .foregroundColor: isHighlighted ? NSColor.white : NSColor(calibratedWhite: 0.35, alpha: 1)
                ]
                NSAttributedString(string: "›", attributes: arrowAttrs)
                    .draw(at: CGPoint(x: rowRect.maxX - 18, y: rowRect.minY + 7))
            }

            itemIndex += 1
        }
    }

    NSGraphicsContext.current?.restoreGraphicsState()
    return panelSize
}

private extension MenuRow {
    var isDivider: Bool {
        if case .divider = self { return true }
        return false
    }
}
