import Testing
import Foundation
@testable import Trolly

@Suite("CursorTrackerSettings")
struct CursorTrackerSettingsTests {

    // MARK: - Defaults

    @Test("default settings have expected values")
    func testDefaults() {
        let settings = CursorTrackerSettings.default

        #expect(settings.enabled == false)
        #expect(settings.highlightStyle == .ring)
        #expect(settings.ringSize == 40)
        #expect(settings.highlightColor == .yellow)
        #expect(settings.highlightOpacity == 0.5)
        #expect(settings.clickEffectEnabled == true)
        #expect(settings.clickColor == .yellow)
    }

    // MARK: - Immutable with* methods

    @Test("withEnabled returns new settings")
    func testWithEnabled() {
        let original = CursorTrackerSettings.default
        let updated = original.withEnabled(true)

        #expect(updated.enabled == true)
        #expect(original.enabled == false)
    }

    @Test("withHighlightStyle returns new settings")
    func testWithHighlightStyle() {
        let original = CursorTrackerSettings.default
        let updated = original.withHighlightStyle(.spotlight)

        #expect(updated.highlightStyle == .spotlight)
        #expect(original.highlightStyle == .ring)
    }

    @Test("withRingSize clamps to range 20-100")
    func testWithRingSizeClamping() {
        let low = CursorTrackerSettings.default.withRingSize(5)
        #expect(low.ringSize == 20)

        let high = CursorTrackerSettings.default.withRingSize(200)
        #expect(high.ringSize == 100)

        let mid = CursorTrackerSettings.default.withRingSize(60)
        #expect(mid.ringSize == 60)
    }

    @Test("withHighlightColor returns new settings")
    func testWithHighlightColor() {
        let original = CursorTrackerSettings.default
        let updated = original.withHighlightColor(.red)

        #expect(updated.highlightColor == .red)
        #expect(original.highlightColor == .yellow)
    }

    @Test("withHighlightOpacity clamps to range 0.1-1.0")
    func testWithHighlightOpacityClamping() {
        let low = CursorTrackerSettings.default.withHighlightOpacity(0.01)
        #expect(low.highlightOpacity == 0.1)

        let high = CursorTrackerSettings.default.withHighlightOpacity(2.0)
        #expect(high.highlightOpacity == 1.0)

        let mid = CursorTrackerSettings.default.withHighlightOpacity(0.7)
        #expect(mid.highlightOpacity == 0.7)
    }

    @Test("withClickEffectEnabled returns new settings")
    func testWithClickEffectEnabled() {
        let original = CursorTrackerSettings.default
        let updated = original.withClickEffectEnabled(false)

        #expect(updated.clickEffectEnabled == false)
        #expect(original.clickEffectEnabled == true)
    }

    @Test("withClickColor returns new settings")
    func testWithClickColor() {
        let original = CursorTrackerSettings.default
        let updated = original.withClickColor(.blue)

        #expect(updated.clickColor == .blue)
        #expect(original.clickColor == .yellow)
    }

    // MARK: - Codable

    @Test("Codable round-trip preserves all fields")
    func testCodableRoundTrip() throws {
        let settings = CursorTrackerSettings.default
            .withEnabled(true)
            .withHighlightStyle(.spotlight)
            .withRingSize(60)
            .withHighlightColor(.blue)
            .withHighlightOpacity(0.8)
            .withClickEffectEnabled(false)
            .withClickColor(.red)

        let data = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(CursorTrackerSettings.self, from: data)

        #expect(decoded == settings)
    }

    // MARK: - Immutability preservation

    @Test("with* methods preserve unrelated fields")
    func testFieldPreservation() {
        let custom = CursorTrackerSettings.default
            .withEnabled(true)
            .withHighlightStyle(.spotlight)
            .withRingSize(80)

        let updated = custom.withClickColor(.green)

        #expect(updated.enabled == true)
        #expect(updated.highlightStyle == .spotlight)
        #expect(updated.ringSize == 80)
        #expect(updated.clickColor == .green)
    }
}
