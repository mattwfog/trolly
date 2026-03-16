import Testing
import Foundation
@testable import Trolly

@Suite("WebcamOverlaySettings")
struct WebcamOverlaySettingsTests {

    // MARK: - Defaults

    @Test("default settings have expected values")
    func testDefaults() {
        let settings = WebcamOverlaySettings.default

        #expect(settings.position == .bottomLeft)
        #expect(settings.size == .medium)
        #expect(settings.shape == .circle)
        #expect(settings.opacity == 1.0)
        #expect(settings.showBorder == true)
    }

    // MARK: - Immutable with* methods

    @Test("withPosition returns new settings")
    func testWithPosition() {
        let original = WebcamOverlaySettings.default
        let updated = original.withPosition(.topRight)

        #expect(updated.position == .topRight)
        #expect(original.position == .bottomLeft)
    }

    @Test("withSize returns new settings")
    func testWithSize() {
        let original = WebcamOverlaySettings.default
        let updated = original.withSize(.large)

        #expect(updated.size == .large)
        #expect(original.size == .medium)
    }

    @Test("withShape returns new settings")
    func testWithShape() {
        let original = WebcamOverlaySettings.default
        let updated = original.withShape(.roundedRect)

        #expect(updated.shape == .roundedRect)
        #expect(original.shape == .circle)
    }

    @Test("withOpacity returns new settings")
    func testWithOpacity() {
        let original = WebcamOverlaySettings.default
        let updated = original.withOpacity(0.7)

        #expect(updated.opacity == 0.7)
        #expect(original.opacity == 1.0)
    }

    @Test("withOpacity clamps to minimum 0.3")
    func testWithOpacityClampsMin() {
        let updated = WebcamOverlaySettings.default.withOpacity(0.1)
        #expect(updated.opacity == 0.3)
    }

    @Test("withOpacity clamps to maximum 1.0")
    func testWithOpacityClampsMax() {
        let updated = WebcamOverlaySettings.default.withOpacity(1.5)
        #expect(updated.opacity == 1.0)
    }

    @Test("withShowBorder returns new settings")
    func testWithShowBorder() {
        let original = WebcamOverlaySettings.default
        let updated = original.withShowBorder(false)

        #expect(updated.showBorder == false)
        #expect(original.showBorder == true)
    }

    // MARK: - Codable round-trip

    @Test("Codable round-trip preserves all fields")
    func testCodableRoundTrip() throws {
        let settings = WebcamOverlaySettings.default
            .withPosition(.topLeft)
            .withSize(.small)
            .withShape(.roundedRect)
            .withOpacity(0.6)
            .withShowBorder(false)

        let data = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(WebcamOverlaySettings.self, from: data)

        #expect(decoded == settings)
    }
}
