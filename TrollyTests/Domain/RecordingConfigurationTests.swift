import Testing
import Foundation
import CoreGraphics
@testable import Trolly

@Suite("RecordingConfiguration")
struct RecordingConfigurationTests {

    @Test("Default configuration has expected values")
    func defaultValues() {
        let config = RecordingConfiguration.default

        #expect(config.captureSource == nil)
        #expect(config.captureFrameRate == 30)
        #expect(config.captureResolution == nil)
        #expect(config.webcamEnabled == true)
        #expect(config.webcamPosition == .bottomLeft)
        #expect(config.webcamSize == .medium)
        #expect(config.microphoneEnabled == true)
        #expect(config.outputFilename == nil)
    }

    @Test("Default configuration is invalid without capture source")
    func defaultIsInvalid() {
        let config = RecordingConfiguration.default

        #expect(!config.isValid)
    }

    @Test("Configuration with capture source is valid")
    func validWithSource() {
        let display = DisplayInfo(id: 1, displayName: "Main", width: 1920, height: 1080)
        let config = RecordingConfiguration.default
            .withCaptureSource(.fullScreen(display: display))

        #expect(config.isValid)
    }

    @Test("withCaptureSource returns new configuration")
    func withCaptureSource() {
        let display = DisplayInfo(id: 1, displayName: "Main", width: 1920, height: 1080)
        let original = RecordingConfiguration.default
        let updated = original.withCaptureSource(.fullScreen(display: display))

        #expect(updated.captureSource != nil)
        #expect(original.captureSource == nil) // original unchanged
    }

    @Test("withWebcam returns new configuration")
    func withWebcam() {
        let original = RecordingConfiguration.default
        let updated = original.withWebcam(enabled: false)

        #expect(updated.webcamEnabled == false)
        #expect(original.webcamEnabled == true) // original unchanged
    }

    @Test("withMicrophone returns new configuration")
    func withMicrophone() {
        let original = RecordingConfiguration.default
        let updated = original.withMicrophone(enabled: false)

        #expect(updated.microphoneEnabled == false)
        #expect(original.microphoneEnabled == true) // original unchanged
    }

    @Test("withWebcamPosition returns new configuration")
    func withWebcamPosition() {
        let original = RecordingConfiguration.default
        let updated = original.withWebcamPosition(.topRight)

        #expect(updated.webcamPosition == .topRight)
        #expect(original.webcamPosition == .bottomLeft) // original unchanged
    }

    @Test("Frame rate boundaries")
    func frameRateBounds() {
        #expect(RecordingConfiguration.minFrameRate == 1)
        #expect(RecordingConfiguration.maxFrameRate == 60)
        #expect(RecordingConfiguration.defaultFrameRate == 30)
    }

    @Test("Default output directory is in Movies/Trolly")
    func outputDirectory() {
        let dir = RecordingConfiguration.defaultOutputDirectory

        #expect(dir.lastPathComponent == "Trolly")
        #expect(dir.pathComponents.contains("Movies"))
    }
}
