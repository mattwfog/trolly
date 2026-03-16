import Foundation

enum RecordingStatus: Equatable, Sendable {
    case idle
    case preparing
    case recording(startedAt: Date)
    case paused(elapsed: TimeInterval)
    case stopping
    case failed(TrollyError)
}

struct RecordingState: Equatable, Sendable {
    let status: RecordingStatus
    let configuration: RecordingConfiguration
    let elapsedTime: TimeInterval

    static func initial(configuration: RecordingConfiguration = .default) -> RecordingState {
        RecordingState(status: .idle, configuration: configuration, elapsedTime: 0)
    }

    func transitioning(to newStatus: RecordingStatus) -> RecordingState {
        RecordingState(
            status: newStatus,
            configuration: configuration,
            elapsedTime: elapsedTime
        )
    }

    func withElapsedTime(_ elapsed: TimeInterval) -> RecordingState {
        RecordingState(
            status: status,
            configuration: configuration,
            elapsedTime: elapsed
        )
    }

    func withConfiguration(_ newConfig: RecordingConfiguration) -> RecordingState {
        RecordingState(
            status: status,
            configuration: newConfig,
            elapsedTime: elapsedTime
        )
    }

    var isRecording: Bool {
        if case .recording = status { return true }
        return false
    }

    var isPaused: Bool {
        if case .paused = status { return true }
        return false
    }

    var isIdle: Bool {
        status == .idle
    }

    var canStart: Bool {
        status == .idle
    }

    var canStop: Bool {
        switch status {
        case .recording, .paused:
            return true
        default:
            return false
        }
    }

    var canPause: Bool {
        if case .recording = status { return true }
        return false
    }

    var canResume: Bool {
        if case .paused = status { return true }
        return false
    }
}
