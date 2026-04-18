import AppKit
import Foundation

enum IconError: Error, CustomStringConvertible {
    case invalidArguments
    case imageLoadFailed(String)
    case setIconFailed(String)

    var description: String {
        switch self {
        case .invalidArguments:
            return "Usage: swift Scripts/set_bundle_icon.swift <bundle-path> <image-path>"
        case .imageLoadFailed(let path):
            return "Failed to load image at \(path)"
        case .setIconFailed(let path):
            return "Failed to set icon for bundle at \(path)"
        }
    }
}

let arguments = CommandLine.arguments
guard arguments.count == 3 else {
    throw IconError.invalidArguments
}

let bundlePath = (arguments[1] as NSString).expandingTildeInPath
let imagePath = (arguments[2] as NSString).expandingTildeInPath

guard let image = NSImage(contentsOfFile: imagePath) else {
    throw IconError.imageLoadFailed(imagePath)
}

let didSetIcon = NSWorkspace.shared.setIcon(image, forFile: bundlePath, options: [])
guard didSetIcon else {
    throw IconError.setIconFailed(bundlePath)
}

print("Set custom icon for \(bundlePath)")
