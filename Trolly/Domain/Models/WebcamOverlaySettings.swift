import Foundation
import CoreGraphics

struct WebcamOverlaySettings: Codable, Equatable, Sendable {
    let position: WebcamPosition
    let size: WebcamSize
    let shape: WebcamShape
    let opacity: Double
    let showBorder: Bool

    static let `default` = WebcamOverlaySettings(
        position: .bottomLeft,
        size: .medium,
        shape: .circle,
        opacity: 1.0,
        showBorder: true
    )

    func withPosition(_ position: WebcamPosition) -> WebcamOverlaySettings {
        WebcamOverlaySettings(
            position: position,
            size: size,
            shape: shape,
            opacity: opacity,
            showBorder: showBorder
        )
    }

    func withSize(_ size: WebcamSize) -> WebcamOverlaySettings {
        WebcamOverlaySettings(
            position: position,
            size: size,
            shape: shape,
            opacity: opacity,
            showBorder: showBorder
        )
    }

    func withShape(_ shape: WebcamShape) -> WebcamOverlaySettings {
        WebcamOverlaySettings(
            position: position,
            size: size,
            shape: shape,
            opacity: opacity,
            showBorder: showBorder
        )
    }

    func withOpacity(_ opacity: Double) -> WebcamOverlaySettings {
        let clamped = min(max(opacity, 0.3), 1.0)
        return WebcamOverlaySettings(
            position: position,
            size: size,
            shape: shape,
            opacity: clamped,
            showBorder: showBorder
        )
    }

    func withShowBorder(_ show: Bool) -> WebcamOverlaySettings {
        WebcamOverlaySettings(
            position: position,
            size: size,
            shape: shape,
            opacity: opacity,
            showBorder: show
        )
    }
}

enum WebcamShape: String, Codable, CaseIterable, Sendable {
    case circle
    case roundedRect

    var label: String {
        switch self {
        case .circle: return "Circle"
        case .roundedRect: return "Rounded Rectangle"
        }
    }

    var icon: String {
        switch self {
        case .circle: return "circle.fill"
        case .roundedRect: return "rectangle.roundedtop.fill"
        }
    }
}
