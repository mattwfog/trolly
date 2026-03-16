import Testing
import Foundation
import CoreGraphics
import CoreMedia
@testable import Trolly

@Suite("VideoWriter")
struct VideoWriterTests {

    private func makeTempURL() -> URL {
        let dir = FileManager.default.temporaryDirectory
        return dir.appendingPathComponent("test-\(UUID().uuidString).mp4")
    }

    // MARK: - Setup Tests

    @Test("Setup with valid parameters succeeds")
    func setupWithValidParameters() throws {
        let writer = VideoWriter()
        let url = makeTempURL()

        try writer.setup(
            outputURL: url,
            videoSize: CGSize(width: 1920, height: 1080),
            hasWebcam: false,
            webcamPosition: .bottomLeft,
            webcamSize: .medium,
            hasAudio: false
        )

        // If we get here without throwing, setup succeeded
        // Clean up
        try? FileManager.default.removeItem(at: url)
    }

    @Test("Setup with audio enabled succeeds")
    func setupWithAudio() throws {
        let writer = VideoWriter()
        let url = makeTempURL()

        try writer.setup(
            outputURL: url,
            videoSize: CGSize(width: 1920, height: 1080),
            hasWebcam: false,
            webcamPosition: .bottomLeft,
            webcamSize: .medium,
            hasAudio: true
        )

        try? FileManager.default.removeItem(at: url)
    }

    @Test("Setup with webcam enabled succeeds")
    func setupWithWebcam() throws {
        let writer = VideoWriter()
        let url = makeTempURL()

        try writer.setup(
            outputURL: url,
            videoSize: CGSize(width: 1920, height: 1080),
            hasWebcam: true,
            webcamPosition: .topRight,
            webcamSize: .large,
            hasAudio: false
        )

        try? FileManager.default.removeItem(at: url)
    }

    @Test("Setup with invalid URL throws assetWriterSetupFailed")
    func setupWithInvalidURL() {
        let writer = VideoWriter()
        let invalidURL = URL(fileURLWithPath: "/nonexistent/path/that/does/not/exist/output.mp4")

        #expect(throws: TrollyError.self) {
            try writer.setup(
                outputURL: invalidURL,
                videoSize: CGSize(width: 1920, height: 1080),
                hasWebcam: false,
                webcamPosition: .bottomLeft,
                webcamSize: .medium,
                hasAudio: false
            )
        }
    }

    @Test("Setup configures correct video dimensions")
    func setupConfiguresCorrectDimensions() throws {
        let writer = VideoWriter()
        let url = makeTempURL()
        let size = CGSize(width: 2560, height: 1440)

        try writer.setup(
            outputURL: url,
            videoSize: size,
            hasWebcam: false,
            webcamPosition: .bottomLeft,
            webcamSize: .medium,
            hasAudio: false
        )

        #expect(writer.configuredVideoSize == size)

        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - Finish Writing Tests

    @Test("finishWriting without setup throws assetWriterNotReady")
    func finishWritingWithoutSetup() async {
        let writer = VideoWriter()

        await #expect(throws: TrollyError.assetWriterNotReady) {
            try await writer.finishWriting()
        }
    }

    @Test("finishWriting after setup returns output URL")
    func finishWritingReturnsURL() async throws {
        let writer = VideoWriter()
        let url = makeTempURL()

        try writer.setup(
            outputURL: url,
            videoSize: CGSize(width: 1920, height: 1080),
            hasWebcam: false,
            webcamPosition: .bottomLeft,
            webcamSize: .medium,
            hasAudio: false
        )

        let resultURL = try await writer.finishWriting()
        #expect(resultURL == url)

        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - State Management Tests

    @Test("Calling setup twice reconfigures the writer")
    func setupTwiceReconfigures() throws {
        let writer = VideoWriter()
        let url1 = makeTempURL()
        let url2 = makeTempURL()

        try writer.setup(
            outputURL: url1,
            videoSize: CGSize(width: 1920, height: 1080),
            hasWebcam: false,
            webcamPosition: .bottomLeft,
            webcamSize: .medium,
            hasAudio: false
        )

        try writer.setup(
            outputURL: url2,
            videoSize: CGSize(width: 1280, height: 720),
            hasWebcam: false,
            webcamPosition: .bottomLeft,
            webcamSize: .medium,
            hasAudio: false
        )

        #expect(writer.configuredVideoSize == CGSize(width: 1280, height: 720))

        try? FileManager.default.removeItem(at: url1)
        try? FileManager.default.removeItem(at: url2)
    }

    // MARK: - WebcamPosition calculation tests

    @Test("Webcam position bottom-left places in correct quadrant",
          arguments: WebcamPosition.allCases)
    func webcamPositionCalculation(position: WebcamPosition) {
        let videoSize = CGSize(width: 1920, height: 1080)
        let webcamDiameter: CGFloat = 200
        let padding: CGFloat = 20

        let origin = VideoWriter.calculateWebcamOrigin(
            position: position,
            videoSize: videoSize,
            webcamDiameter: webcamDiameter,
            padding: padding
        )

        switch position {
        case .bottomLeft:
            #expect(origin.x == padding)
            #expect(origin.y == padding)
        case .bottomRight:
            #expect(origin.x == videoSize.width - webcamDiameter - padding)
            #expect(origin.y == padding)
        case .topLeft:
            #expect(origin.x == padding)
            #expect(origin.y == videoSize.height - webcamDiameter - padding)
        case .topRight:
            #expect(origin.x == videoSize.width - webcamDiameter - padding)
            #expect(origin.y == videoSize.height - webcamDiameter - padding)
        }
    }
}
