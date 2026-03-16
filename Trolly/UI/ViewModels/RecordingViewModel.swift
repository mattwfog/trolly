import Foundation
import Observation

@Observable
@MainActor
final class RecordingViewModel {
    private let coordinator: RecordingCoordinator
    private let permissionManager: PermissionManager

    private(set) var configuration: RecordingConfiguration = .default
    private(set) var errorMessage: String?

    init(
        coordinator: RecordingCoordinator,
        permissionManager: PermissionManager
    ) {
        self.coordinator = coordinator
        self.permissionManager = permissionManager
    }

    // MARK: - Computed State

    var isRecording: Bool { coordinator.state.isRecording }
    var isPaused: Bool { coordinator.state.isPaused }
    var isIdle: Bool { coordinator.state.isIdle }
    var canStart: Bool { coordinator.state.canStart }
    var canStop: Bool { coordinator.state.canStop }
    var canPause: Bool { coordinator.state.canPause }
    var canResume: Bool { coordinator.state.canResume }
    var elapsedTime: TimeInterval { coordinator.state.elapsedTime }

    var elapsedTimeFormatted: String {
        formatElapsedTime(elapsedTime)
    }

    func formatElapsedTime(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)
        let minutes = totalSeconds / 60
        let remainingSeconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }

    // MARK: - Actions

    func startRecording() async {
        do {
            try await coordinator.startRecording(with: configuration)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func stopRecording() async {
        do {
            _ = try await coordinator.stopRecording()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func pauseRecording() async {
        do {
            try await coordinator.pauseRecording()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func resumeRecording() async {
        do {
            try await coordinator.resumeRecording()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func selectSource(_ source: CaptureSource) {
        configuration = configuration.withCaptureSource(source)
    }

    func toggleWebcam() {
        configuration = configuration.withWebcam(enabled: !configuration.webcamEnabled)
    }

    func toggleMicrophone() {
        configuration = configuration.withMicrophone(enabled: !configuration.microphoneEnabled)
    }

    func dismissError() {
        errorMessage = nil
    }
}
