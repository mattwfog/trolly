import Testing
import Foundation
@testable import Trolly

@Suite("RecordingCoordinator Source Switching")
struct RecordingCoordinatorSourceSwitchTests {

    @MainActor
    private func makeCoordinator() -> (
        RecordingCoordinator,
        MockScreenCaptureProvider,
        MockCameraCaptureProvider,
        MockAudioCaptureProvider,
        MockVideoWriter,
        MockRecordingRepository
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

    private func makeDisplay(id: UInt32 = 1, name: String = "Test Display") -> DisplayInfo {
        DisplayInfo(id: id, displayName: name, width: 1920, height: 1080)
    }

    private func makeWindow(id: UInt32 = 100, title: String = "Test Window") -> WindowInfo {
        WindowInfo(
            id: id,
            title: title,
            applicationName: "TestApp",
            frame: CGRect(x: 0, y: 0, width: 800, height: 600)
        )
    }

    private func makeConfig(source: CaptureSource? = nil) -> RecordingConfiguration {
        RecordingConfiguration(
            captureSource: source,
            captureFrameRate: 30,
            captureResolution: nil,
            webcamEnabled: false,
            webcamPosition: .bottomLeft,
            webcamSize: .medium,
            microphoneEnabled: false,
            outputDirectory: URL(fileURLWithPath: "/tmp"),
            outputFilename: "test"
        )
    }

    // MARK: - Switch Source Tests

    @Test("switchSource updates content filter while recording")
    @MainActor
    func testSwitchSourceWhileRecording() async throws {
        let (coordinator, screenCapture, _, _, _, _) = makeCoordinator()

        let display1 = makeDisplay(id: 1, name: "Display 1")
        let display2 = makeDisplay(id: 2, name: "Display 2")
        let source1 = CaptureSource.fullScreen(display: display1)
        let source2 = CaptureSource.fullScreen(display: display2)

        let config = makeConfig(source: source1)
        try await coordinator.startRecording(with: config)

        #expect(coordinator.state.isRecording)
        #expect(screenCapture.lastCaptureSource == source1)

        try await coordinator.switchSource(to: source2)

        #expect(screenCapture.switchSourceCallCount == 1)
        #expect(screenCapture.switchedSources.last == source2)
        #expect(coordinator.state.configuration.captureSource == source2)
    }

    @Test("switchSource works when paused")
    @MainActor
    func testSwitchSourceWhilePaused() async throws {
        let (coordinator, screenCapture, _, _, _, _) = makeCoordinator()

        let display = makeDisplay()
        let window = makeWindow()
        let source1 = CaptureSource.fullScreen(display: display)
        let source2 = CaptureSource.window(window: window)

        try await coordinator.startRecording(with: makeConfig(source: source1))
        try await coordinator.pauseRecording()

        #expect(coordinator.state.isPaused)

        try await coordinator.switchSource(to: source2)

        #expect(screenCapture.switchSourceCallCount == 1)
        #expect(screenCapture.switchedSources.last == source2)
    }

    @Test("switchSource throws when idle")
    @MainActor
    func testSwitchSourceWhenIdle() async {
        let (coordinator, _, _, _, _, _) = makeCoordinator()

        let display = makeDisplay()
        let source = CaptureSource.fullScreen(display: display)

        do {
            try await coordinator.switchSource(to: source)
            #expect(Bool(false), "Should have thrown")
        } catch {
            #expect(error is TrollyError)
        }
    }

    @Test("switchSource from display to window")
    @MainActor
    func testSwitchDisplayToWindow() async throws {
        let (coordinator, screenCapture, _, _, _, _) = makeCoordinator()

        let display = makeDisplay()
        let window = makeWindow()
        let source1 = CaptureSource.fullScreen(display: display)
        let source2 = CaptureSource.window(window: window)

        try await coordinator.startRecording(with: makeConfig(source: source1))
        try await coordinator.switchSource(to: source2)

        #expect(screenCapture.switchedSources.count == 1)
        #expect(screenCapture.switchedSources[0] == source2)
    }

    @Test("switchSource from window to region")
    @MainActor
    func testSwitchWindowToRegion() async throws {
        let (coordinator, screenCapture, _, _, _, _) = makeCoordinator()

        let window = makeWindow()
        let display = makeDisplay()
        let source1 = CaptureSource.window(window: window)
        let source2 = CaptureSource.region(
            display: display,
            rect: CGRect(x: 0, y: 0, width: 640, height: 480)
        )

        try await coordinator.startRecording(with: makeConfig(source: source1))
        try await coordinator.switchSource(to: source2)

        #expect(screenCapture.switchedSources.count == 1)
        #expect(screenCapture.switchedSources[0] == source2)
    }

    @Test("switchSource multiple times updates correctly")
    @MainActor
    func testMultipleSwitches() async throws {
        let (coordinator, screenCapture, _, _, _, _) = makeCoordinator()

        let display1 = makeDisplay(id: 1, name: "Display 1")
        let display2 = makeDisplay(id: 2, name: "Display 2")
        let window = makeWindow()

        let source1 = CaptureSource.fullScreen(display: display1)
        let source2 = CaptureSource.fullScreen(display: display2)
        let source3 = CaptureSource.window(window: window)

        try await coordinator.startRecording(with: makeConfig(source: source1))
        try await coordinator.switchSource(to: source2)
        try await coordinator.switchSource(to: source3)

        #expect(screenCapture.switchSourceCallCount == 2)
        #expect(screenCapture.switchedSources.count == 2)
        #expect(screenCapture.switchedSources[1] == source3)
        #expect(coordinator.state.configuration.captureSource == source3)
    }
}
