import Foundation
import CoreGraphics

struct VideoPlayerSettings: Codable, Equatable, Sendable {
    let transcriptPosition: TranscriptPanelPosition
    let transcriptPanelSize: TranscriptPanelSize
    let transcriptAutoScroll: Bool
    let transcriptVisibleByDefault: Bool
    let transcriptFontSize: TranscriptFontSize
    let transcriptShowTimestamps: Bool
    let timestampFormat: TimestampFormat
    let playbackRate: PlaybackRate
    let loopPlayback: Bool
    let autoPlay: Bool

    static let `default` = VideoPlayerSettings(
        transcriptPosition: .right,
        transcriptPanelSize: .medium,
        transcriptAutoScroll: true,
        transcriptVisibleByDefault: true,
        transcriptFontSize: .medium,
        transcriptShowTimestamps: true,
        timestampFormat: .minuteSecond,
        playbackRate: .normal,
        loopPlayback: false,
        autoPlay: false
    )

    func withTranscriptPosition(_ position: TranscriptPanelPosition) -> VideoPlayerSettings {
        VideoPlayerSettings(
            transcriptPosition: position,
            transcriptPanelSize: transcriptPanelSize,
            transcriptAutoScroll: transcriptAutoScroll,
            transcriptVisibleByDefault: transcriptVisibleByDefault,
            transcriptFontSize: transcriptFontSize,
            transcriptShowTimestamps: transcriptShowTimestamps,
            timestampFormat: timestampFormat,
            playbackRate: playbackRate,
            loopPlayback: loopPlayback,
            autoPlay: autoPlay
        )
    }

    func withTranscriptPanelSize(_ size: TranscriptPanelSize) -> VideoPlayerSettings {
        VideoPlayerSettings(
            transcriptPosition: transcriptPosition,
            transcriptPanelSize: size,
            transcriptAutoScroll: transcriptAutoScroll,
            transcriptVisibleByDefault: transcriptVisibleByDefault,
            transcriptFontSize: transcriptFontSize,
            transcriptShowTimestamps: transcriptShowTimestamps,
            timestampFormat: timestampFormat,
            playbackRate: playbackRate,
            loopPlayback: loopPlayback,
            autoPlay: autoPlay
        )
    }

    func withTranscriptAutoScroll(_ enabled: Bool) -> VideoPlayerSettings {
        VideoPlayerSettings(
            transcriptPosition: transcriptPosition,
            transcriptPanelSize: transcriptPanelSize,
            transcriptAutoScroll: enabled,
            transcriptVisibleByDefault: transcriptVisibleByDefault,
            transcriptFontSize: transcriptFontSize,
            transcriptShowTimestamps: transcriptShowTimestamps,
            timestampFormat: timestampFormat,
            playbackRate: playbackRate,
            loopPlayback: loopPlayback,
            autoPlay: autoPlay
        )
    }

    func withTranscriptVisibleByDefault(_ visible: Bool) -> VideoPlayerSettings {
        VideoPlayerSettings(
            transcriptPosition: transcriptPosition,
            transcriptPanelSize: transcriptPanelSize,
            transcriptAutoScroll: transcriptAutoScroll,
            transcriptVisibleByDefault: visible,
            transcriptFontSize: transcriptFontSize,
            transcriptShowTimestamps: transcriptShowTimestamps,
            timestampFormat: timestampFormat,
            playbackRate: playbackRate,
            loopPlayback: loopPlayback,
            autoPlay: autoPlay
        )
    }

    func withTranscriptFontSize(_ size: TranscriptFontSize) -> VideoPlayerSettings {
        VideoPlayerSettings(
            transcriptPosition: transcriptPosition,
            transcriptPanelSize: transcriptPanelSize,
            transcriptAutoScroll: transcriptAutoScroll,
            transcriptVisibleByDefault: transcriptVisibleByDefault,
            transcriptFontSize: size,
            transcriptShowTimestamps: transcriptShowTimestamps,
            timestampFormat: timestampFormat,
            playbackRate: playbackRate,
            loopPlayback: loopPlayback,
            autoPlay: autoPlay
        )
    }

    func withTranscriptShowTimestamps(_ show: Bool) -> VideoPlayerSettings {
        VideoPlayerSettings(
            transcriptPosition: transcriptPosition,
            transcriptPanelSize: transcriptPanelSize,
            transcriptAutoScroll: transcriptAutoScroll,
            transcriptVisibleByDefault: transcriptVisibleByDefault,
            transcriptFontSize: transcriptFontSize,
            transcriptShowTimestamps: show,
            timestampFormat: timestampFormat,
            playbackRate: playbackRate,
            loopPlayback: loopPlayback,
            autoPlay: autoPlay
        )
    }

    func withTimestampFormat(_ format: TimestampFormat) -> VideoPlayerSettings {
        VideoPlayerSettings(
            transcriptPosition: transcriptPosition,
            transcriptPanelSize: transcriptPanelSize,
            transcriptAutoScroll: transcriptAutoScroll,
            transcriptVisibleByDefault: transcriptVisibleByDefault,
            transcriptFontSize: transcriptFontSize,
            transcriptShowTimestamps: transcriptShowTimestamps,
            timestampFormat: format,
            playbackRate: playbackRate,
            loopPlayback: loopPlayback,
            autoPlay: autoPlay
        )
    }

    func withPlaybackRate(_ rate: PlaybackRate) -> VideoPlayerSettings {
        VideoPlayerSettings(
            transcriptPosition: transcriptPosition,
            transcriptPanelSize: transcriptPanelSize,
            transcriptAutoScroll: transcriptAutoScroll,
            transcriptVisibleByDefault: transcriptVisibleByDefault,
            transcriptFontSize: transcriptFontSize,
            transcriptShowTimestamps: transcriptShowTimestamps,
            timestampFormat: timestampFormat,
            playbackRate: rate,
            loopPlayback: loopPlayback,
            autoPlay: autoPlay
        )
    }

    func withLoopPlayback(_ loop: Bool) -> VideoPlayerSettings {
        VideoPlayerSettings(
            transcriptPosition: transcriptPosition,
            transcriptPanelSize: transcriptPanelSize,
            transcriptAutoScroll: transcriptAutoScroll,
            transcriptVisibleByDefault: transcriptVisibleByDefault,
            transcriptFontSize: transcriptFontSize,
            transcriptShowTimestamps: transcriptShowTimestamps,
            timestampFormat: timestampFormat,
            playbackRate: playbackRate,
            loopPlayback: loop,
            autoPlay: autoPlay
        )
    }

    func withAutoPlay(_ auto: Bool) -> VideoPlayerSettings {
        VideoPlayerSettings(
            transcriptPosition: transcriptPosition,
            transcriptPanelSize: transcriptPanelSize,
            transcriptAutoScroll: transcriptAutoScroll,
            transcriptVisibleByDefault: transcriptVisibleByDefault,
            transcriptFontSize: transcriptFontSize,
            transcriptShowTimestamps: transcriptShowTimestamps,
            timestampFormat: timestampFormat,
            playbackRate: playbackRate,
            loopPlayback: loopPlayback,
            autoPlay: auto
        )
    }
}

// MARK: - Transcript Enums

enum TranscriptPanelPosition: String, Codable, CaseIterable, Sendable {
    case left
    case right
    case bottom

    var label: String {
        switch self {
        case .left: return "Left"
        case .right: return "Right"
        case .bottom: return "Bottom"
        }
    }

    var icon: String {
        switch self {
        case .left: return "sidebar.left"
        case .right: return "sidebar.right"
        case .bottom: return "rectangle.bottomhalf.filled"
        }
    }
}

enum TranscriptPanelSize: String, Codable, CaseIterable, Sendable {
    case narrow
    case medium
    case wide

    var label: String {
        switch self {
        case .narrow: return "Narrow"
        case .medium: return "Medium"
        case .wide: return "Wide"
        }
    }

    var sideWidth: CGFloat {
        switch self {
        case .narrow: return 200
        case .medium: return 280
        case .wide: return 360
        }
    }

    var bottomHeight: CGFloat {
        switch self {
        case .narrow: return 120
        case .medium: return 180
        case .wide: return 260
        }
    }
}

enum TranscriptFontSize: String, Codable, CaseIterable, Sendable {
    case small
    case medium
    case large

    var label: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        }
    }

    var textSize: CGFloat {
        switch self {
        case .small: return 11
        case .medium: return 13
        case .large: return 15
        }
    }

    var timestampSize: CGFloat {
        switch self {
        case .small: return 9
        case .medium: return 10
        case .large: return 12
        }
    }
}

enum TimestampFormat: String, Codable, CaseIterable, Sendable {
    case minuteSecond
    case hourMinuteSecond

    var label: String {
        switch self {
        case .minuteSecond: return "m:ss"
        case .hourMinuteSecond: return "h:mm:ss"
        }
    }

    func format(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        switch self {
        case .minuteSecond:
            let m = total / 60
            let s = total % 60
            return String(format: "%d:%02d", m, s)
        case .hourMinuteSecond:
            let h = total / 3600
            let m = (total % 3600) / 60
            let s = total % 60
            return String(format: "%d:%02d:%02d", h, m, s)
        }
    }
}

// MARK: - Playback Enums

enum PlaybackRate: String, Codable, CaseIterable, Sendable {
    case half
    case threeQuarters
    case normal
    case oneAndQuarter
    case oneAndHalf
    case double

    var label: String {
        switch self {
        case .half: return "0.5x"
        case .threeQuarters: return "0.75x"
        case .normal: return "1x"
        case .oneAndQuarter: return "1.25x"
        case .oneAndHalf: return "1.5x"
        case .double: return "2x"
        }
    }

    var rate: Float {
        switch self {
        case .half: return 0.5
        case .threeQuarters: return 0.75
        case .normal: return 1.0
        case .oneAndQuarter: return 1.25
        case .oneAndHalf: return 1.5
        case .double: return 2.0
        }
    }
}
