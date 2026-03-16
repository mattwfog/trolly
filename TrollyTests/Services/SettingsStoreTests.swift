import Testing
import Foundation
@testable import Trolly

@Suite("SettingsStore")
struct SettingsStoreTests {

    private func makeIsolatedDefaults() -> UserDefaults {
        let suiteName = "trolly-test-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        return defaults
    }

    private func cleanupDefaults(_ defaults: UserDefaults) {
        defaults.removePersistentDomain(forName: defaults.description)
    }

    // MARK: - Video Player Settings

    @Test("loads default video player settings when none persisted")
    @MainActor
    func testDefaultVideoPlayerSettings() {
        let defaults = makeIsolatedDefaults()
        let store = SettingsStore(defaults: defaults)

        #expect(store.videoPlayerSettings == VideoPlayerSettings.default)
    }

    @Test("persists and loads video player settings")
    @MainActor
    func testPersistVideoPlayerSettings() {
        let defaults = makeIsolatedDefaults()
        let store = SettingsStore(defaults: defaults)

        let updated = VideoPlayerSettings.default
            .withTranscriptPosition(.bottom)
            .withPlaybackRate(.double)
        store.updateVideoPlayerSettings(updated)

        let store2 = SettingsStore(defaults: defaults)
        #expect(store2.videoPlayerSettings == updated)
    }

    @Test("reset video player settings restores defaults")
    @MainActor
    func testResetVideoPlayerSettings() {
        let defaults = makeIsolatedDefaults()
        let store = SettingsStore(defaults: defaults)

        let updated = VideoPlayerSettings.default.withPlaybackRate(.half)
        store.updateVideoPlayerSettings(updated)
        #expect(store.videoPlayerSettings.playbackRate == .half)

        store.resetVideoPlayerSettings()
        #expect(store.videoPlayerSettings == VideoPlayerSettings.default)
    }

    // MARK: - Webcam Overlay Settings

    @Test("loads default webcam overlay settings when none persisted")
    @MainActor
    func testDefaultWebcamOverlaySettings() {
        let defaults = makeIsolatedDefaults()
        let store = SettingsStore(defaults: defaults)

        #expect(store.webcamOverlaySettings == WebcamOverlaySettings.default)
    }

    @Test("persists and loads webcam overlay settings")
    @MainActor
    func testPersistWebcamOverlaySettings() {
        let defaults = makeIsolatedDefaults()
        let store = SettingsStore(defaults: defaults)

        let updated = WebcamOverlaySettings.default
            .withPosition(.topRight)
            .withShape(.roundedRect)
            .withOpacity(0.8)
        store.updateWebcamOverlaySettings(updated)

        let store2 = SettingsStore(defaults: defaults)
        #expect(store2.webcamOverlaySettings == updated)
    }

    @Test("reset webcam overlay settings restores defaults")
    @MainActor
    func testResetWebcamOverlaySettings() {
        let defaults = makeIsolatedDefaults()
        let store = SettingsStore(defaults: defaults)

        let updated = WebcamOverlaySettings.default.withShape(.roundedRect)
        store.updateWebcamOverlaySettings(updated)
        #expect(store.webcamOverlaySettings.shape == .roundedRect)

        store.resetWebcamOverlaySettings()
        #expect(store.webcamOverlaySettings == WebcamOverlaySettings.default)
    }

    // MARK: - Independence

    @Test("updating video settings does not affect webcam settings")
    @MainActor
    func testSettingsIndependence() {
        let defaults = makeIsolatedDefaults()
        let store = SettingsStore(defaults: defaults)

        let originalWebcam = store.webcamOverlaySettings
        store.updateVideoPlayerSettings(
            VideoPlayerSettings.default.withPlaybackRate(.double)
        )

        #expect(store.webcamOverlaySettings == originalWebcam)
    }
}
