import Testing
import Foundation
@testable import Trolly

@Suite("RecordingState")
struct RecordingStateTests {

    @Test("Initial state is idle with zero elapsed time")
    func initialState() {
        let state = RecordingState.initial()

        #expect(state.isIdle)
        #expect(state.elapsedTime == 0)
        #expect(state.canStart)
        #expect(!state.canStop)
        #expect(!state.canPause)
        #expect(!state.canResume)
    }

    @Test("Transitioning to recording updates status")
    func transitionToRecording() {
        let state = RecordingState.initial()
        let now = Date()
        let recording = state.transitioning(to: .recording(startedAt: now))

        #expect(recording.isRecording)
        #expect(!recording.isIdle)
        #expect(recording.canStop)
        #expect(recording.canPause)
        #expect(!recording.canStart)
        #expect(!recording.canResume)
    }

    @Test("Transitioning to paused updates status")
    func transitionToPaused() {
        let state = RecordingState.initial()
            .transitioning(to: .recording(startedAt: Date()))
            .transitioning(to: .paused(elapsed: 5.0))

        #expect(state.isPaused)
        #expect(state.canStop)
        #expect(state.canResume)
        #expect(!state.canStart)
        #expect(!state.canPause)
    }

    @Test("Transitioning preserves configuration")
    func transitionPreservesConfiguration() {
        let config = RecordingConfiguration.default.withMicrophone(enabled: false)
        let state = RecordingState.initial(configuration: config)
            .transitioning(to: .recording(startedAt: Date()))

        #expect(state.configuration == config)
        #expect(state.configuration.microphoneEnabled == false)
    }

    @Test("withElapsedTime returns new state with updated time")
    func withElapsedTime() {
        let state = RecordingState.initial()
            .transitioning(to: .recording(startedAt: Date()))
        let updated = state.withElapsedTime(10.5)

        #expect(updated.elapsedTime == 10.5)
        #expect(updated.isRecording)
        #expect(state.elapsedTime == 0) // original unchanged
    }

    @Test("withConfiguration returns new state with updated config")
    func withConfiguration() {
        let state = RecordingState.initial()
        let newConfig = RecordingConfiguration.default.withWebcam(enabled: false)
        let updated = state.withConfiguration(newConfig)

        #expect(updated.configuration.webcamEnabled == false)
        #expect(state.configuration.webcamEnabled == true) // original unchanged
    }

    @Test("Preparing state cannot start, stop, pause, or resume")
    func preparingState() {
        let state = RecordingState.initial().transitioning(to: .preparing)

        #expect(!state.canStart)
        #expect(!state.canStop)
        #expect(!state.canPause)
        #expect(!state.canResume)
    }

    @Test("Stopping state cannot start, stop, pause, or resume")
    func stoppingState() {
        let state = RecordingState.initial().transitioning(to: .stopping)

        #expect(!state.canStart)
        #expect(!state.canStop)
        #expect(!state.canPause)
        #expect(!state.canResume)
    }

    @Test("Failed state cannot start, stop, pause, or resume")
    func failedState() {
        let state = RecordingState.initial()
            .transitioning(to: .failed(.cameraUnavailable))

        #expect(!state.canStart)
        #expect(!state.canStop)
        #expect(!state.canPause)
        #expect(!state.canResume)
    }
}
