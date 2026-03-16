import Foundation
import Observation
import CoreMedia
import ScreenCaptureKit

@Observable
@MainActor
final class RecordingCoordinator {
    private(set) var state: RecordingState = .initial()

    private let screenCapture: ScreenCaptureProviding
    private let cameraCapture: CameraCaptureProviding
    private let audioCapture: AudioCaptureProviding
    private let videoWriter: VideoWriting
    private let repository: RecordingRepository

    private var recordingStartDate: Date?
    private var elapsedTimer: Timer?
    private var activeConfiguration: RecordingConfiguration?

    init(
        screenCapture: ScreenCaptureProviding,
        cameraCapture: CameraCaptureProviding,
        audioCapture: AudioCaptureProviding,
        videoWriter: VideoWriting,
        repository: RecordingRepository
    ) {
        self.screenCapture = screenCapture
        self.cameraCapture = cameraCapture
        self.audioCapture = audioCapture
        self.videoWriter = videoWriter
        self.repository = repository
    }

    // MARK: - Public API

    func startRecording(with configuration: RecordingConfiguration) async throws {
        guard state.canStart else {
            throw TrollyError.invalidStateTransition(
                from: statusDescription(state.status),
                to: "recording"
            )
        }

        guard let captureSource = configuration.captureSource else {
            throw TrollyError.noCaptureSourceSelected
        }

        state = state.transitioning(to: .preparing)
            .withConfiguration(configuration)

        let outputURL = try repository.outputURL(for: configuration)

        try setupVideoWriter(
            outputURL: outputURL,
            configuration: configuration,
            captureSource: captureSource
        )

        try await startScreenCapture(
            source: captureSource,
            configuration: configuration
        )

        if configuration.webcamEnabled {
            try await cameraCapture.startCapture { [videoWriter] sampleBuffer in
                try? videoWriter.appendWebcamSample(sampleBuffer)
            }
        }

        if configuration.microphoneEnabled {
            try await audioCapture.startCapture { [videoWriter] sampleBuffer in
                try? videoWriter.appendAudioSample(sampleBuffer)
            }
        }

        let now = Date()
        recordingStartDate = now
        activeConfiguration = configuration
        state = state.transitioning(to: .recording(startedAt: now))
        startElapsedTimer()
    }

    func pauseRecording() async throws {
        guard state.canPause else {
            throw TrollyError.invalidStateTransition(
                from: statusDescription(state.status),
                to: "paused"
            )
        }

        stopElapsedTimer()
        state = state.transitioning(to: .paused(elapsed: state.elapsedTime))
    }

    func resumeRecording() async throws {
        guard state.canResume else {
            throw TrollyError.invalidStateTransition(
                from: statusDescription(state.status),
                to: "recording"
            )
        }

        let now = Date()
        recordingStartDate = now
        state = state.transitioning(to: .recording(startedAt: now))
        startElapsedTimer()
    }

    func switchSource(to source: CaptureSource) async throws {
        guard state.isRecording || state.isPaused else {
            throw TrollyError.invalidStateTransition(
                from: statusDescription(state.status),
                to: "switching source"
            )
        }

        guard let config = activeConfiguration else {
            throw TrollyError.invalidConfiguration("No active configuration")
        }

        let updatedConfig = config.withCaptureSource(source)
        try await screenCapture.switchSource(to: source, configuration: updatedConfig)
        activeConfiguration = updatedConfig
        state = state.withConfiguration(updatedConfig)
    }

    func stopRecording() async throws -> URL {
        guard state.canStop else {
            throw TrollyError.invalidStateTransition(
                from: statusDescription(state.status),
                to: "idle"
            )
        }

        let elapsed = state.elapsedTime
        state = state.transitioning(to: .stopping)
        stopElapsedTimer()

        try await stopAllCaptures()

        let outputURL = try await videoWriter.finishWriting()

        try await saveMetadata(
            outputURL: outputURL,
            elapsed: elapsed
        )

        state = .initial()
        recordingStartDate = nil
        activeConfiguration = nil

        return outputURL
    }

    // MARK: - Private Helpers

    private func setupVideoWriter(
        outputURL: URL,
        configuration: RecordingConfiguration,
        captureSource: CaptureSource
    ) throws {
        let videoSize = configuration.captureResolution ?? captureSource.resolution
        try videoWriter.setup(
            outputURL: outputURL,
            videoSize: videoSize,
            hasWebcam: configuration.webcamEnabled,
            webcamPosition: configuration.webcamPosition,
            webcamSize: configuration.webcamSize,
            hasAudio: configuration.microphoneEnabled
        )
    }

    private func startScreenCapture(
        source: CaptureSource,
        configuration: RecordingConfiguration
    ) async throws {
        try await screenCapture.startCapture(
            source: source,
            configuration: configuration
        ) { [videoWriter] sampleBuffer, outputType in
            guard outputType == .screen else { return }
            try? videoWriter.appendVideoSample(sampleBuffer)
        }
    }

    private func stopAllCaptures() async throws {
        try await screenCapture.stopCapture()

        if activeConfiguration?.webcamEnabled == true {
            try await cameraCapture.stopCapture()
        }

        if activeConfiguration?.microphoneEnabled == true {
            try await audioCapture.stopCapture()
        }
    }

    private func saveMetadata(
        outputURL: URL,
        elapsed: TimeInterval
    ) async throws {
        let fileSize = fileSize(at: outputURL)
        let config = activeConfiguration ?? .default

        let metadata = RecordingMetadata.create(
            duration: elapsed,
            fileURL: outputURL,
            fileSize: fileSize,
            sourceName: config.captureSource?.displayName ?? "Unknown",
            hasWebcam: config.webcamEnabled,
            hasAudio: config.microphoneEnabled
        )

        try await repository.save(metadata: metadata)
    }

    private func fileSize(at url: URL) -> Int64 {
        let attributes = try? FileManager.default.attributesOfItem(
            atPath: url.path
        )
        return (attributes?[.size] as? Int64) ?? 0
    }

    private func startElapsedTimer() {
        let baseElapsed = state.elapsedTime
        let startDate = Date()
        elapsedTimer = Timer.scheduledTimer(
            withTimeInterval: 0.1,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.state.isRecording else { return }
                let now = Date()
                let delta = now.timeIntervalSince(startDate)
                self.state = self.state.withElapsedTime(baseElapsed + delta)
            }
        }
    }

    private func stopElapsedTimer() {
        elapsedTimer?.invalidate()
        elapsedTimer = nil
    }

    private func statusDescription(_ status: RecordingStatus) -> String {
        switch status {
        case .idle: return "idle"
        case .preparing: return "preparing"
        case .recording: return "recording"
        case .paused: return "paused"
        case .stopping: return "stopping"
        case .failed: return "failed"
        }
    }
}
