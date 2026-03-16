import Testing
import Foundation
@testable import Trolly

@Suite("TeleprompterSettings")
struct TeleprompterSettingsTests {

    // MARK: - Defaults

    @Test("default settings have expected values")
    func testDefaults() {
        let settings = TeleprompterSettings.default

        #expect(settings.fontSize == .large)
        #expect(settings.scrollSpeed == .medium)
        #expect(settings.textColor == .white)
        #expect(settings.backgroundColor == .black)
        #expect(settings.backgroundOpacity == 0.85)
        #expect(settings.mirrorHorizontally == false)
        #expect(settings.showCountdown == true)
        #expect(settings.countdownSeconds == 3)
    }

    // MARK: - Immutable with* methods

    @Test("withFontSize returns new settings")
    func testWithFontSize() {
        let original = TeleprompterSettings.default
        let updated = original.withFontSize(.extraLarge)

        #expect(updated.fontSize == .extraLarge)
        #expect(original.fontSize == .large)
    }

    @Test("withScrollSpeed returns new settings")
    func testWithScrollSpeed() {
        let original = TeleprompterSettings.default
        let updated = original.withScrollSpeed(.fast)

        #expect(updated.scrollSpeed == .fast)
        #expect(original.scrollSpeed == .medium)
    }

    @Test("withTextColor returns new settings")
    func testWithTextColor() {
        let original = TeleprompterSettings.default
        let updated = original.withTextColor(.green)

        #expect(updated.textColor == .green)
        #expect(original.textColor == .white)
    }

    @Test("withBackgroundColor returns new settings")
    func testWithBackgroundColor() {
        let original = TeleprompterSettings.default
        let updated = original.withBackgroundColor(.green)

        #expect(updated.backgroundColor == .green)
        #expect(original.backgroundColor == .black)
    }

    @Test("withBackgroundOpacity clamps to range 0.3-1.0")
    func testWithBackgroundOpacityClamping() {
        let low = TeleprompterSettings.default.withBackgroundOpacity(0.1)
        #expect(low.backgroundOpacity == 0.3)

        let high = TeleprompterSettings.default.withBackgroundOpacity(1.5)
        #expect(high.backgroundOpacity == 1.0)

        let mid = TeleprompterSettings.default.withBackgroundOpacity(0.6)
        #expect(mid.backgroundOpacity == 0.6)
    }

    @Test("withMirrorHorizontally returns new settings")
    func testWithMirror() {
        let original = TeleprompterSettings.default
        let updated = original.withMirrorHorizontally(true)

        #expect(updated.mirrorHorizontally == true)
        #expect(original.mirrorHorizontally == false)
    }

    @Test("withShowCountdown returns new settings")
    func testWithShowCountdown() {
        let original = TeleprompterSettings.default
        let updated = original.withShowCountdown(false)

        #expect(updated.showCountdown == false)
        #expect(original.showCountdown == true)
    }

    @Test("withCountdownSeconds clamps to range 1-10")
    func testWithCountdownSecondsClamping() {
        let low = TeleprompterSettings.default.withCountdownSeconds(0)
        #expect(low.countdownSeconds == 1)

        let high = TeleprompterSettings.default.withCountdownSeconds(20)
        #expect(high.countdownSeconds == 10)

        let mid = TeleprompterSettings.default.withCountdownSeconds(5)
        #expect(mid.countdownSeconds == 5)
    }

    // MARK: - Codable

    @Test("Codable round-trip preserves all fields")
    func testCodableRoundTrip() throws {
        let settings = TeleprompterSettings.default
            .withFontSize(.small)
            .withScrollSpeed(.veryFast)
            .withTextColor(.yellow)
            .withBackgroundColor(.green)
            .withBackgroundOpacity(0.5)
            .withMirrorHorizontally(true)
            .withShowCountdown(false)
            .withCountdownSeconds(7)

        let data = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(TeleprompterSettings.self, from: data)

        #expect(decoded == settings)
    }

    // MARK: - Enum values

    @Test("TeleprompterFontSize has correct point sizes")
    func testFontSizePoints() {
        #expect(TeleprompterFontSize.small.points == 18)
        #expect(TeleprompterFontSize.medium.points == 24)
        #expect(TeleprompterFontSize.large.points == 32)
        #expect(TeleprompterFontSize.extraLarge.points == 42)
    }

    @Test("ScrollSpeed has correct points per second")
    func testScrollSpeedValues() {
        #expect(ScrollSpeed.slow.pointsPerSecond == 20)
        #expect(ScrollSpeed.medium.pointsPerSecond == 40)
        #expect(ScrollSpeed.fast.pointsPerSecond == 65)
        #expect(ScrollSpeed.veryFast.pointsPerSecond == 100)
    }
}
