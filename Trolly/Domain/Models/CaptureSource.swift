import Foundation
import CoreGraphics

enum CaptureSource: Equatable, Sendable {
    case fullScreen(display: DisplayInfo)
    case window(window: WindowInfo)
    case region(display: DisplayInfo, rect: CGRect)

    var displayName: String {
        switch self {
        case .fullScreen(let display):
            return display.displayName
        case .window(let window):
            return "\(window.applicationName) - \(window.title)"
        case .region(let display, _):
            return "Region on \(display.displayName)"
        }
    }

    var isDisplay: Bool {
        if case .fullScreen = self { return true }
        return false
    }

    var resolution: CGSize {
        switch self {
        case .fullScreen(let display):
            return CGSize(width: display.width, height: display.height)
        case .window(let window):
            return window.frame.size
        case .region(_, let rect):
            return rect.size
        }
    }

    var aspectRatio: CGFloat {
        let size = resolution
        guard size.height > 0 else { return 16.0 / 9.0 }
        return size.width / size.height
    }
}

struct DisplayInfo: Equatable, Sendable, Identifiable {
    let id: CGDirectDisplayID
    let displayName: String
    let width: Int
    let height: Int
}

struct WindowInfo: Equatable, Sendable, Identifiable {
    let id: CGWindowID
    let title: String
    let applicationName: String
    let frame: CGRect
}
