import Testing
import Foundation
@testable import Trolly

@Suite("RecordingViewModel")
struct RecordingViewModelTests {

    // MARK: - Helpers

    private static let testDisplay = DisplayInfo(
        id: 1,
        displayName: "Test Display",
        width: 1920,
        height: 1080
    )
    private static let testSource = CaptureSource.fullScreen(display: testDisplay)

    @MainActor
    private static func makeSUT() -> (
        viewModel: RecordingViewModel,
        coordinator: RecordingCoordinator,
        permissionManager: PermissionManager
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
        let permissionManager = PermissionManager(
            screenCaptureChecker: { true },
            screenCaptureRequester: { true },
            avAuthorizationStatus: { _ in .authorized },
            avRequestAccess: { _ in true }
        )
        let viewModel = RecordingViewModel(
            coordinator: coordinator,
            permissionManager: permissionManager
        )
        return (viewModel, coordinator, permissionManager)
    }

    // MARK: - Initial State

    @Test("Initial state is idle")
    @MainActor
    func testInitialState_isIdle() {
        let (viewModel, _, _) = Self.makeSUT()

        #expect(viewModel.isIdle)
        #expect(!viewModel.isRecording)
        #expect(!viewModel.isPaused)
        #expect(viewModel.canStart)
        #expect(!viewModel.canStop)
        #expect(!viewModel.canPause)
        #expect(!viewModel.canResume)
    }

    // MARK: - elapsedTimeFormatted

    @Test("elapsedTimeFormatted returns 00:00 when idle")
    @MainActor
    func testElapsedTimeFormatted_whenIdle_returnsZero() {
        let (viewModel, _, _) = Self.makeSUT()

        #expect(viewModel.elapsedTimeFormatted == "00:00")
    }

    @Test("elapsedTimeFormatted formats correctly for 125 seconds")
    @MainActor
    func testElapsedTimeFormatted_formats125Seconds() {
        let (viewModel, _, _) = Self.makeSUT()

        #expect(viewModel.formatElapsedTime(125.0) == "02:05")
    }

    @Test("elapsedTimeFormatted formats correctly for 0 seconds")
    @MainActor
    func testElapsedTimeFormatted_formatsZero() {
        let (viewModel, _, _) = Self.makeSUT()

        #expect(viewModel.formatElapsedTime(0.0) == "00:00")
    }

    @Test("elapsedTimeFormatted formats correctly for 59 seconds")
    @MainActor
    func testElapsedTimeFormatted_formats59Seconds() {
        let (viewModel, _, _) = Self.makeSUT()

        #expect(viewModel.formatElapsedTime(59.0) == "00:59")
    }

    @Test("elapsedTimeFormatted formats correctly for 3600 seconds")
    @MainActor
    func testElapsedTimeFormatted_formats3600Seconds() {
        let (viewModel, _, _) = Self.makeSUT()

        #expect(viewModel.formatElapsedTime(3600.0) == "60:00")
    }

    // MARK: - selectSource

    @Test("selectSource updates configuration")
    @MainActor
    func testSelectSource_updatesConfiguration() {
        let (viewModel, _, _) = Self.makeSUT()

        viewModel.selectSource(Self.testSource)

        #expect(viewModel.configuration.captureSource == Self.testSource)
    }

    // MARK: - toggleWebcam

    @Test("toggleWebcam toggles webcam enabled")
    @MainActor
    func testToggleWebcam_togglesWebcamEnabled() {
        let (viewModel, _, _) = Self.makeSUT()
        let initialValue = viewModel.configuration.webcamEnabled

        viewModel.toggleWebcam()

        #expect(viewModel.configuration.webcamEnabled == !initialValue)
    }

    // MARK: - toggleMicrophone

    @Test("toggleMicrophone toggles microphone enabled")
    @MainActor
    func testToggleMicrophone_togglesMicrophoneEnabled() {
        let (viewModel, _, _) = Self.makeSUT()
        let initialValue = viewModel.configuration.microphoneEnabled

        viewModel.toggleMicrophone()

        #expect(viewModel.configuration.microphoneEnabled == !initialValue)
    }

    // MARK: - startRecording

    @Test("startRecording with valid config calls coordinator")
    @MainActor
    func testStartRecording_withValidConfig_callsCoordinator() async {
        let (viewModel, coordinator, _) = Self.makeSUT()
        viewModel.selectSource(Self.testSource)

        await viewModel.startRecording()

        #expect(coordinator.state.isRecording)
        #expect(viewModel.errorMessage == nil)
    }

    @Test("startRecording without source sets errorMessage")
    @MainActor
    func testStartRecording_withoutSource_setsErrorMessage() async {
        let (viewModel, _, _) = Self.makeSUT()

        await viewModel.startRecording()

        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.isIdle)
    }

    // MARK: - stopRecording

    @Test("stopRecording calls coordinator and returns")
    @MainActor
    func testStopRecording_callsCoordinatorAndReturns() async {
        let (viewModel, coordinator, _) = Self.makeSUT()
        viewModel.selectSource(Self.testSource)

        await viewModel.startRecording()
        #expect(coordinator.state.isRecording)

        await viewModel.stopRecording()

        #expect(coordinator.state.isIdle)
        #expect(viewModel.errorMessage == nil)
    }

    // MARK: - dismissError

    @Test("dismissError clears errorMessage")
    @MainActor
    func testDismissError_clearsErrorMessage() async {
        let (viewModel, _, _) = Self.makeSUT()

        // Trigger an error first
        await viewModel.startRecording()
        #expect(viewModel.errorMessage != nil)

        viewModel.dismissError()

        #expect(viewModel.errorMessage == nil)
    }
}
