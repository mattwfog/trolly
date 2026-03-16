import Testing
import Foundation
@testable import Trolly

@Suite("RecordingCoordinator")
struct RecordingCoordinatorTests {

    // MARK: - Helpers

    private static let testDisplay = DisplayInfo(
        id: 1,
        displayName: "Test Display",
        width: 1920,
        height: 1080
    )
    private static let testSource = CaptureSource.fullScreen(display: testDisplay)
    private static let testOutputURL = URL(fileURLWithPath: "/tmp/trolly-test/recording.mp4")

    private static func makeValidConfig(
        webcamEnabled: Bool = true,
        microphoneEnabled: Bool = true
    ) -> RecordingConfiguration {
        RecordingConfiguration.default
            .withCaptureSource(testSource)
            .withWebcam(enabled: webcamEnabled)
            .withMicrophone(enabled: microphoneEnabled)
    }

    @MainActor
    private static func makeSUT() -> (
        coordinator: RecordingCoordinator,
        screenCapture: MockScreenCaptureProvider,
        cameraCapture: MockCameraCaptureProvider,
        audioCapture: MockAudioCaptureProvider,
        videoWriter: MockVideoWriter,
        repository: MockRecordingRepository
    ) {
        let screenCapture = MockScreenCaptureProvider()
        let cameraCapture = MockCameraCaptureProvider()
        let audioCapture = MockAudioCaptureProvider()
        let videoWriter = MockVideoWriter()
        let repository = MockRecordingRepository()
        let coordinator = RecordingCoordinator(
            screenCapture: screenCapture,
            cameraCapture: cameraCapture,
            audioCapture: audioCapture,
            videoWriter: videoWriter,
            repository: repository
        )
        return (coordinator, screenCapture, cameraCapture, audioCapture, videoWriter, repository)
    }

    // MARK: - startRecording

    @Test("startRecording transitions to recording state")
    @MainActor
    func testStartRecording_transitionsToRecording() async throws {
        let (coordinator, _, _, _, _, _) = Self.makeSUT()
        let config = Self.makeValidConfig()

        try await coordinator.startRecording(with: config)

        #expect(coordinator.state.isRecording)
    }

    @Test("startRecording starts screen capture")
    @MainActor
    func testStartRecording_startsScreenCapture() async throws {
        let (coordinator, screenCapture, _, _, _, _) = Self.makeSUT()
        let config = Self.makeValidConfig()

        try await coordinator.startRecording(with: config)

        #expect(screenCapture.startCaptureCallCount == 1)
    }

    @Test("startRecording with webcam enabled starts camera capture")
    @MainActor
    func testStartRecording_withWebcam_startsCamera() async throws {
        let (coordinator, _, cameraCapture, _, _, _) = Self.makeSUT()
        let config = Self.makeValidConfig(webcamEnabled: true)

        try await coordinator.startRecording(with: config)

        #expect(cameraCapture.startCaptureCallCount == 1)
    }

    @Test("startRecording with webcam disabled skips camera capture")
    @MainActor
    func testStartRecording_withoutWebcam_skipsCamera() async throws {
        let (coordinator, _, cameraCapture, _, _, _) = Self.makeSUT()
        let config = Self.makeValidConfig(webcamEnabled: false)

        try await coordinator.startRecording(with: config)

        #expect(cameraCapture.startCaptureCallCount == 0)
    }

    @Test("startRecording with microphone enabled starts audio capture")
    @MainActor
    func testStartRecording_withMic_startsAudio() async throws {
        let (coordinator, _, _, audioCapture, _, _) = Self.makeSUT()
        let config = Self.makeValidConfig(microphoneEnabled: true)

        try await coordinator.startRecording(with: config)

        #expect(audioCapture.startCaptureCallCount == 1)
    }

    @Test("startRecording with microphone disabled skips audio capture")
    @MainActor
    func testStartRecording_withoutMic_skipsAudio() async throws {
        let (coordinator, _, _, audioCapture, _, _) = Self.makeSUT()
        let config = Self.makeValidConfig(microphoneEnabled: false)

        try await coordinator.startRecording(with: config)

        #expect(audioCapture.startCaptureCallCount == 0)
    }

    @Test("startRecording sets up video writer")
    @MainActor
    func testStartRecording_setupsVideoWriter() async throws {
        let (coordinator, _, _, _, videoWriter, _) = Self.makeSUT()
        let config = Self.makeValidConfig()

        try await coordinator.startRecording(with: config)

        #expect(videoWriter.setupCallCount == 1)
    }

    @Test("startRecording when already recording throws invalidStateTransition")
    @MainActor
    func testStartRecording_whenAlreadyRecording_throws() async throws {
        let (coordinator, _, _, _, _, _) = Self.makeSUT()
        let config = Self.makeValidConfig()

        try await coordinator.startRecording(with: config)

        await #expect(throws: TrollyError.self) {
            try await coordinator.startRecording(with: config)
        }
    }

    @Test("startRecording without capture source throws noCaptureSourceSelected")
    @MainActor
    func testStartRecording_withoutCaptureSource_throws() async throws {
        let (coordinator, _, _, _, _, _) = Self.makeSUT()
        let config = RecordingConfiguration.default // no capture source

        await #expect(throws: TrollyError.noCaptureSourceSelected) {
            try await coordinator.startRecording(with: config)
        }
    }

    // MARK: - stopRecording

    @Test("stopRecording transitions to idle state")
    @MainActor
    func testStopRecording_transitionsToIdle() async throws {
        let (coordinator, _, _, _, _, _) = Self.makeSUT()
        let config = Self.makeValidConfig()

        try await coordinator.startRecording(with: config)
        _ = try await coordinator.stopRecording()

        #expect(coordinator.state.isIdle)
    }

    @Test("stopRecording stops all capture services")
    @MainActor
    func testStopRecording_stopsAllCaptures() async throws {
        let (coordinator, screenCapture, cameraCapture, audioCapture, _, _) = Self.makeSUT()
        let config = Self.makeValidConfig(webcamEnabled: true, microphoneEnabled: true)

        try await coordinator.startRecording(with: config)
        _ = try await coordinator.stopRecording()

        #expect(screenCapture.stopCaptureCallCount == 1)
        #expect(cameraCapture.stopCaptureCallCount == 1)
        #expect(audioCapture.stopCaptureCallCount == 1)
    }

    @Test("stopRecording finishes video writing")
    @MainActor
    func testStopRecording_finishesWriting() async throws {
        let (coordinator, _, _, _, videoWriter, _) = Self.makeSUT()
        let config = Self.makeValidConfig()

        try await coordinator.startRecording(with: config)
        _ = try await coordinator.stopRecording()

        #expect(videoWriter.finishWritingCallCount == 1)
    }

    @Test("stopRecording returns output URL")
    @MainActor
    func testStopRecording_returnsOutputURL() async throws {
        let (coordinator, _, _, _, videoWriter, _) = Self.makeSUT()
        let expectedURL = URL(fileURLWithPath: "/tmp/test-output.mp4")
        videoWriter.finishWritingURL = expectedURL
        let config = Self.makeValidConfig()

        try await coordinator.startRecording(with: config)
        let outputURL = try await coordinator.stopRecording()

        #expect(outputURL == expectedURL)
    }

    @Test("stopRecording when idle throws invalidStateTransition")
    @MainActor
    func testStopRecording_whenIdle_throws() async throws {
        let (coordinator, _, _, _, _, _) = Self.makeSUT()

        await #expect(throws: TrollyError.self) {
            _ = try await coordinator.stopRecording()
        }
    }

    // MARK: - pauseRecording

    @Test("pauseRecording transitions to paused state")
    @MainActor
    func testPauseRecording_transitionsToPaused() async throws {
        let (coordinator, _, _, _, _, _) = Self.makeSUT()
        let config = Self.makeValidConfig()

        try await coordinator.startRecording(with: config)
        try await coordinator.pauseRecording()

        #expect(coordinator.state.isPaused)
    }

    @Test("pauseRecording when not recording throws invalidStateTransition")
    @MainActor
    func testPauseRecording_whenNotRecording_throws() async throws {
        let (coordinator, _, _, _, _, _) = Self.makeSUT()

        await #expect(throws: TrollyError.self) {
            try await coordinator.pauseRecording()
        }
    }

    // MARK: - resumeRecording

    @Test("resumeRecording transitions to recording state")
    @MainActor
    func testResumeRecording_transitionsToRecording() async throws {
        let (coordinator, _, _, _, _, _) = Self.makeSUT()
        let config = Self.makeValidConfig()

        try await coordinator.startRecording(with: config)
        try await coordinator.pauseRecording()
        try await coordinator.resumeRecording()

        #expect(coordinator.state.isRecording)
    }

    @Test("resumeRecording when not paused throws invalidStateTransition")
    @MainActor
    func testResumeRecording_whenNotPaused_throws() async throws {
        let (coordinator, _, _, _, _, _) = Self.makeSUT()

        await #expect(throws: TrollyError.self) {
            try await coordinator.resumeRecording()
        }
    }
}
