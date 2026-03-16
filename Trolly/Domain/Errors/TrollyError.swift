import Foundation

enum TrollyError: Error, Equatable, Sendable {
    // Permission errors
    case screenCapturePermissionDenied
    case cameraPermissionDenied
    case microphonePermissionDenied

    // Capture errors
    case noDisplaysAvailable
    case noWindowsAvailable
    case captureStreamFailed(String)
    case previewStreamFailed(String)
    case cameraUnavailable
    case microphoneUnavailable

    // Configuration errors
    case noCaptureSourceSelected
    case invalidFrameRate(Int)
    case invalidConfiguration(String)

    // Writing errors
    case assetWriterSetupFailed(String)
    case assetWriterNotReady
    case assetWriterAppendFailed(String)
    case outputDirectoryNotWritable(String)

    // Storage errors
    case recordingNotFound(UUID)
    case storageFailed(String)

    // State errors
    case invalidStateTransition(from: String, to: String)

    // Transcription errors
    case transcriptionFailed(String)
    case transcriptionServerUnavailable
}

extension TrollyError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .screenCapturePermissionDenied:
            return "Screen capture permission is required. Please enable it in System Settings > Privacy & Security > Screen Recording."
        case .cameraPermissionDenied:
            return "Camera permission is required for webcam overlay."
        case .microphonePermissionDenied:
            return "Microphone permission is required for audio recording."
        case .noDisplaysAvailable:
            return "No displays available for capture."
        case .noWindowsAvailable:
            return "No windows available for capture."
        case .captureStreamFailed(let reason):
            return "Screen capture failed: \(reason)"
        case .previewStreamFailed(let reason):
            return "Preview stream failed: \(reason)"
        case .cameraUnavailable:
            return "No camera device found."
        case .microphoneUnavailable:
            return "No microphone device found."
        case .noCaptureSourceSelected:
            return "Please select a screen or window to record."
        case .invalidFrameRate(let rate):
            return "Invalid frame rate: \(rate). Must be between \(RecordingConfiguration.minFrameRate) and \(RecordingConfiguration.maxFrameRate)."
        case .invalidConfiguration(let reason):
            return "Invalid recording configuration: \(reason)"
        case .assetWriterSetupFailed(let reason):
            return "Failed to set up video writer: \(reason)"
        case .assetWriterNotReady:
            return "Video writer is not ready to accept samples."
        case .assetWriterAppendFailed(let reason):
            return "Failed to write video data: \(reason)"
        case .outputDirectoryNotWritable(let path):
            return "Cannot write to output directory: \(path)"
        case .recordingNotFound(let id):
            return "Recording not found: \(id)"
        case .storageFailed(let reason):
            return "Storage operation failed: \(reason)"
        case .invalidStateTransition(let from, let to):
            return "Cannot transition from \(from) to \(to)."
        case .transcriptionFailed(let reason):
            return "Transcription failed: \(reason)"
        case .transcriptionServerUnavailable:
            return "Transcription server is not running. Start it with transcription-server/start.sh"
        }
    }
}
