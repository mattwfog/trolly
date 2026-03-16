import Foundation
import Observation

@Observable
@MainActor
final class AppState {
    let permissionManager: PermissionManager
    let recordingCoordinator: RecordingCoordinator
    let capturePreviewViewModel: CapturePreviewViewModel

    private(set) var availableDisplays: [DisplayInfo] = []
    private(set) var availableWindows: [WindowInfo] = []
    private(set) var isLoadingSources: Bool = false
    private(set) var errorMessage: String?

    let repository: RecordingStorageRepository
    private(set) var recordings: [RecordingMetadata] = []
    private(set) var isLoadingRecordings: Bool = false

    let transcriptionService: TranscriptionService
    let transcriptStorage: TranscriptStorageService
    private(set) var transcribingRecordingIDs: Set<UUID> = []
    private(set) var transcribedRecordingIDs: Set<UUID> = []

    let settingsStore: SettingsStore
    let scriptStorage: ScriptStorageService
    let cursorTracker: CursorTracker
    private(set) var activeScript: Script?

    private let screenCapture: ScreenCaptureProviding

    init() {
        let screenCapture = ScreenCaptureService()
        let cameraCapture = CameraCaptureService()
        let audioCapture = AudioCaptureService()
        let videoWriter = VideoWriter()
        let repository = RecordingStorageRepository()

        let previewService = CapturePreviewService()

        self.screenCapture = screenCapture
        self.repository = repository
        self.permissionManager = PermissionManager()
        self.capturePreviewViewModel = CapturePreviewViewModel(previewService: previewService)
        self.recordingCoordinator = RecordingCoordinator(
            screenCapture: screenCapture,
            cameraCapture: cameraCapture,
            audioCapture: audioCapture,
            videoWriter: videoWriter,
            repository: repository
        )
        self.transcriptionService = TranscriptionService()
        self.transcriptStorage = TranscriptStorageService()
        self.settingsStore = SettingsStore()
        self.scriptStorage = ScriptStorageService()
        self.cursorTracker = CursorTracker()
    }

    func loadRecordings() async {
        isLoadingRecordings = true
        defer { isLoadingRecordings = false }

        do {
            recordings = try await repository.fetchAll()
            refreshTranscriptionStatus()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteRecording(id: UUID) async {
        do {
            try await repository.delete(id: id)
            recordings = recordings.filter { $0.id != id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadAvailableSources() async {
        isLoadingSources = true
        defer { isLoadingSources = false }

        do {
            let displays = try await screenCapture.availableDisplays()
            let windows = try await screenCapture.availableWindows()
            availableDisplays = displays
            availableWindows = windows
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Transcription

    func transcribeRecording(id: UUID) async {
        guard let recording = recordings.first(where: { $0.id == id }) else { return }
        guard !transcribingRecordingIDs.contains(id) else { return }

        transcribingRecordingIDs = transcribingRecordingIDs.union([id])
        defer { transcribingRecordingIDs = transcribingRecordingIDs.subtracting([id]) }

        do {
            let transcript = try await transcriptionService.transcribe(filePath: recording.fileURL)
            try await transcriptStorage.save(transcript: transcript, for: recording)
            transcribedRecordingIDs = transcribedRecordingIDs.union([id])
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadTranscript(for recording: RecordingMetadata) async -> Transcript? {
        do {
            return try await transcriptStorage.load(for: recording)
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func refreshTranscriptionStatus() {
        var transcribed = Set<UUID>()
        for recording in recordings {
            if transcriptStorage.exists(for: recording) {
                transcribed.insert(recording.id)
            }
        }
        transcribedRecordingIDs = transcribed
    }

    // MARK: - Scripts

    func setActiveScript(_ script: Script?) {
        activeScript = script
    }

    // MARK: - Source Switching

    func switchRecordingSource(to source: CaptureSource) async {
        do {
            try await recordingCoordinator.switchSource(to: source)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func setError(_ message: String) {
        errorMessage = message
    }

    func clearError() {
        errorMessage = nil
    }
}
