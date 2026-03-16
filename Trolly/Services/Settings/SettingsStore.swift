import Foundation
import Observation

@Observable
@MainActor
final class SettingsStore {

    private(set) var videoPlayerSettings: VideoPlayerSettings
    private(set) var webcamOverlaySettings: WebcamOverlaySettings
    private(set) var teleprompterSettings: TeleprompterSettings
    private(set) var cursorTrackerSettings: CursorTrackerSettings

    private let defaults: UserDefaults
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        return encoder
    }()
    private let decoder = JSONDecoder()

    private static let videoPlayerKey = "trolly.videoPlayerSettings"
    private static let webcamOverlayKey = "trolly.webcamOverlaySettings"
    private static let teleprompterKey = "trolly.teleprompterSettings"
    private static let cursorTrackerKey = "trolly.cursorTrackerSettings"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.videoPlayerSettings = Self.load(
            VideoPlayerSettings.self,
            key: Self.videoPlayerKey,
            from: defaults
        ) ?? .default
        self.webcamOverlaySettings = Self.load(
            WebcamOverlaySettings.self,
            key: Self.webcamOverlayKey,
            from: defaults
        ) ?? .default
        self.teleprompterSettings = Self.load(
            TeleprompterSettings.self,
            key: Self.teleprompterKey,
            from: defaults
        ) ?? .default
        self.cursorTrackerSettings = Self.load(
            CursorTrackerSettings.self,
            key: Self.cursorTrackerKey,
            from: defaults
        ) ?? .default
    }

    // MARK: - Video Player Settings

    func updateVideoPlayerSettings(_ settings: VideoPlayerSettings) {
        videoPlayerSettings = settings
        persist(settings, key: Self.videoPlayerKey)
    }

    // MARK: - Webcam Overlay Settings

    func updateWebcamOverlaySettings(_ settings: WebcamOverlaySettings) {
        webcamOverlaySettings = settings
        persist(settings, key: Self.webcamOverlayKey)
    }

    // MARK: - Teleprompter Settings

    func updateTeleprompterSettings(_ settings: TeleprompterSettings) {
        teleprompterSettings = settings
        persist(settings, key: Self.teleprompterKey)
    }

    // MARK: - Reset

    func resetVideoPlayerSettings() {
        updateVideoPlayerSettings(.default)
    }

    func resetWebcamOverlaySettings() {
        updateWebcamOverlaySettings(.default)
    }

    func resetTeleprompterSettings() {
        updateTeleprompterSettings(.default)
    }

    // MARK: - Cursor Tracker Settings

    func updateCursorTrackerSettings(_ settings: CursorTrackerSettings) {
        cursorTrackerSettings = settings
        persist(settings, key: Self.cursorTrackerKey)
    }

    func resetCursorTrackerSettings() {
        updateCursorTrackerSettings(.default)
    }

    // MARK: - Private

    private func persist<T: Encodable>(_ value: T, key: String) {
        guard let data = try? encoder.encode(value) else { return }
        defaults.set(data, forKey: key)
    }

    private static func load<T: Decodable>(
        _ type: T.Type,
        key: String,
        from defaults: UserDefaults
    ) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
