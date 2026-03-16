import Foundation
import CoreGraphics

struct CursorTrackerSettings: Codable, Equatable, Sendable {
    let enabled: Bool
    let highlightStyle: CursorHighlightStyle
    let ringSize: CGFloat
    let highlightColor: CursorHighlightColor
    let highlightOpacity: Double
    let clickEffectEnabled: Bool
    let clickColor: CursorHighlightColor

    static let `default` = CursorTrackerSettings(
        enabled: false,
        highlightStyle: .ring,
        ringSize: 40,
        highlightColor: .yellow,
        highlightOpacity: 0.5,
        clickEffectEnabled: true,
        clickColor: .yellow
    )

    func withEnabled(_ enabled: Bool) -> CursorTrackerSettings {
        CursorTrackerSettings(
            enabled: enabled,
            highlightStyle: highlightStyle,
            ringSize: ringSize,
            highlightColor: highlightColor,
            highlightOpacity: highlightOpacity,
            clickEffectEnabled: clickEffectEnabled,
            clickColor: clickColor
        )
    }

    func withHighlightStyle(_ style: CursorHighlightStyle) -> CursorTrackerSettings {
        CursorTrackerSettings(
            enabled: enabled,
            highlightStyle: style,
            ringSize: ringSize,
            highlightColor: highlightColor,
            highlightOpacity: highlightOpacity,
            clickEffectEnabled: clickEffectEnabled,
            clickColor: clickColor
        )
    }

    func withRingSize(_ size: CGFloat) -> CursorTrackerSettings {
        let clamped = min(max(size, 20), 100)
        return CursorTrackerSettings(
            enabled: enabled,
            highlightStyle: highlightStyle,
            ringSize: clamped,
            highlightColor: highlightColor,
            highlightOpacity: highlightOpacity,
            clickEffectEnabled: clickEffectEnabled,
            clickColor: clickColor
        )
    }

    func withHighlightColor(_ color: CursorHighlightColor) -> CursorTrackerSettings {
        CursorTrackerSettings(
            enabled: enabled,
            highlightStyle: highlightStyle,
            ringSize: ringSize,
            highlightColor: color,
            highlightOpacity: highlightOpacity,
            clickEffectEnabled: clickEffectEnabled,
            clickColor: clickColor
        )
    }

    func withHighlightOpacity(_ opacity: Double) -> CursorTrackerSettings {
        let clamped = min(max(opacity, 0.1), 1.0)
        return CursorTrackerSettings(
            enabled: enabled,
            highlightStyle: highlightStyle,
            ringSize: ringSize,
            highlightColor: highlightColor,
            highlightOpacity: clamped,
            clickEffectEnabled: clickEffectEnabled,
            clickColor: clickColor
        )
    }

    func withClickEffectEnabled(_ enabled: Bool) -> CursorTrackerSettings {
        CursorTrackerSettings(
            enabled: self.enabled,
            highlightStyle: highlightStyle,
            ringSize: ringSize,
            highlightColor: highlightColor,
            highlightOpacity: highlightOpacity,
            clickEffectEnabled: enabled,
            clickColor: clickColor
        )
    }

    func withClickColor(_ color: CursorHighlightColor) -> CursorTrackerSettings {
        CursorTrackerSettings(
            enabled: enabled,
            highlightStyle: highlightStyle,
            ringSize: ringSize,
            highlightColor: highlightColor,
            highlightOpacity: highlightOpacity,
            clickEffectEnabled: clickEffectEnabled,
            clickColor: color
        )
    }
}

// MARK: - Enums

enum CursorHighlightStyle: String, Codable, CaseIterable, Sendable {
    case ring
    case spotlight

    var label: String {
        switch self {
        case .ring: return "Ring"
        case .spotlight: return "Spotlight"
        }
    }

    var icon: String {
        switch self {
        case .ring: return "circle"
        case .spotlight: return "circle.fill"
        }
    }
}

enum CursorHighlightColor: String, Codable, CaseIterable, Sendable {
    case yellow
    case red
    case blue
    case green
    case white

    var label: String {
        switch self {
        case .yellow: return "Yellow"
        case .red: return "Red"
        case .blue: return "Blue"
        case .green: return "Green"
        case .white: return "White"
        }
    }

}
