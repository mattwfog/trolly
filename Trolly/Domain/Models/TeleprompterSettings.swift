import Foundation
import CoreGraphics

struct TeleprompterSettings: Codable, Equatable, Sendable {
    let fontSize: TeleprompterFontSize
    let scrollSpeed: ScrollSpeed
    let textColor: TeleprompterColor
    let backgroundColor: TeleprompterColor
    let backgroundOpacity: Double
    let mirrorHorizontally: Bool
    let showCountdown: Bool
    let countdownSeconds: Int

    static let `default` = TeleprompterSettings(
        fontSize: .large,
        scrollSpeed: .medium,
        textColor: .white,
        backgroundColor: .black,
        backgroundOpacity: 0.85,
        mirrorHorizontally: false,
        showCountdown: true,
        countdownSeconds: 3
    )

    func withFontSize(_ size: TeleprompterFontSize) -> TeleprompterSettings {
        TeleprompterSettings(
            fontSize: size,
            scrollSpeed: scrollSpeed,
            textColor: textColor,
            backgroundColor: backgroundColor,
            backgroundOpacity: backgroundOpacity,
            mirrorHorizontally: mirrorHorizontally,
            showCountdown: showCountdown,
            countdownSeconds: countdownSeconds
        )
    }

    func withScrollSpeed(_ speed: ScrollSpeed) -> TeleprompterSettings {
        TeleprompterSettings(
            fontSize: fontSize,
            scrollSpeed: speed,
            textColor: textColor,
            backgroundColor: backgroundColor,
            backgroundOpacity: backgroundOpacity,
            mirrorHorizontally: mirrorHorizontally,
            showCountdown: showCountdown,
            countdownSeconds: countdownSeconds
        )
    }

    func withTextColor(_ color: TeleprompterColor) -> TeleprompterSettings {
        TeleprompterSettings(
            fontSize: fontSize,
            scrollSpeed: scrollSpeed,
            textColor: color,
            backgroundColor: backgroundColor,
            backgroundOpacity: backgroundOpacity,
            mirrorHorizontally: mirrorHorizontally,
            showCountdown: showCountdown,
            countdownSeconds: countdownSeconds
        )
    }

    func withBackgroundColor(_ color: TeleprompterColor) -> TeleprompterSettings {
        TeleprompterSettings(
            fontSize: fontSize,
            scrollSpeed: scrollSpeed,
            textColor: textColor,
            backgroundColor: color,
            backgroundOpacity: backgroundOpacity,
            mirrorHorizontally: mirrorHorizontally,
            showCountdown: showCountdown,
            countdownSeconds: countdownSeconds
        )
    }

    func withBackgroundOpacity(_ opacity: Double) -> TeleprompterSettings {
        let clamped = min(max(opacity, 0.3), 1.0)
        return TeleprompterSettings(
            fontSize: fontSize,
            scrollSpeed: scrollSpeed,
            textColor: textColor,
            backgroundColor: backgroundColor,
            backgroundOpacity: clamped,
            mirrorHorizontally: mirrorHorizontally,
            showCountdown: showCountdown,
            countdownSeconds: countdownSeconds
        )
    }

    func withMirrorHorizontally(_ mirror: Bool) -> TeleprompterSettings {
        TeleprompterSettings(
            fontSize: fontSize,
            scrollSpeed: scrollSpeed,
            textColor: textColor,
            backgroundColor: backgroundColor,
            backgroundOpacity: backgroundOpacity,
            mirrorHorizontally: mirror,
            showCountdown: showCountdown,
            countdownSeconds: countdownSeconds
        )
    }

    func withShowCountdown(_ show: Bool) -> TeleprompterSettings {
        TeleprompterSettings(
            fontSize: fontSize,
            scrollSpeed: scrollSpeed,
            textColor: textColor,
            backgroundColor: backgroundColor,
            backgroundOpacity: backgroundOpacity,
            mirrorHorizontally: mirrorHorizontally,
            showCountdown: show,
            countdownSeconds: countdownSeconds
        )
    }

    func withCountdownSeconds(_ seconds: Int) -> TeleprompterSettings {
        let clamped = min(max(seconds, 1), 10)
        return TeleprompterSettings(
            fontSize: fontSize,
            scrollSpeed: scrollSpeed,
            textColor: textColor,
            backgroundColor: backgroundColor,
            backgroundOpacity: backgroundOpacity,
            mirrorHorizontally: mirrorHorizontally,
            showCountdown: showCountdown,
            countdownSeconds: clamped
        )
    }
}

// MARK: - Enums

enum TeleprompterFontSize: String, Codable, CaseIterable, Sendable {
    case small
    case medium
    case large
    case extraLarge

    var label: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        case .extraLarge: return "XL"
        }
    }

    var points: CGFloat {
        switch self {
        case .small: return 18
        case .medium: return 24
        case .large: return 32
        case .extraLarge: return 42
        }
    }
}

enum ScrollSpeed: String, Codable, CaseIterable, Sendable {
    case slow
    case medium
    case fast
    case veryFast

    var label: String {
        switch self {
        case .slow: return "Slow"
        case .medium: return "Medium"
        case .fast: return "Fast"
        case .veryFast: return "Very Fast"
        }
    }

    /// Points per second to scroll
    var pointsPerSecond: CGFloat {
        switch self {
        case .slow: return 20
        case .medium: return 40
        case .fast: return 65
        case .veryFast: return 100
        }
    }
}

enum TeleprompterColor: String, Codable, CaseIterable, Sendable {
    case white
    case black
    case green
    case yellow

    var label: String {
        switch self {
        case .white: return "White"
        case .black: return "Black"
        case .green: return "Green"
        case .yellow: return "Yellow"
        }
    }
}
