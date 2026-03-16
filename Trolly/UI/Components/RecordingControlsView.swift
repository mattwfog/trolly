import SwiftUI

struct RecordingControlsView: View {
    let state: RecordingState
    let webcamEnabled: Bool
    let microphoneEnabled: Bool
    let onStart: () -> Void
    let onStop: () -> Void
    let onPause: () -> Void
    let onResume: () -> Void
    let onToggleWebcam: () -> Void
    let onToggleMicrophone: () -> Void

    var body: some View {
        HStack(spacing: 20) {
            toggleGroup
            Spacer()
            primaryAction
            Spacer()
            pauseResumeAction
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    // MARK: - Primary Action

    @ViewBuilder
    private var primaryAction: some View {
        if state.isIdle {
            Button(action: onStart) {
                ZStack {
                    Circle()
                        .fill(.red)
                        .frame(width: 56, height: 56)
                    Circle()
                        .fill(.red.opacity(0.8))
                        .frame(width: 44, height: 44)
                    Circle()
                        .fill(.white)
                        .frame(width: 20, height: 20)
                }
            }
            .buttonStyle(.plain)
            .help("Start recording")
        } else {
            Button(action: onStop) {
                ZStack {
                    Circle()
                        .fill(.red.opacity(0.15))
                        .frame(width: 56, height: 56)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.red)
                        .frame(width: 20, height: 20)
                }
            }
            .buttonStyle(.plain)
            .disabled(!state.canStop)
            .help("Stop recording")
        }
    }

    // MARK: - Pause / Resume

    @ViewBuilder
    private var pauseResumeAction: some View {
        if state.isPaused {
            Button(action: onResume) {
                VStack(spacing: 4) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.green)
                    Text("Resume")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .frame(width: 50)
            }
            .buttonStyle(.plain)
        } else if state.isRecording {
            Button(action: onPause) {
                VStack(spacing: 4) {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.primary)
                    Text("Pause")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .frame(width: 50)
            }
            .buttonStyle(.plain)
        } else {
            Color.clear.frame(width: 50, height: 40)
        }
    }

    // MARK: - Toggles

    private var toggleGroup: some View {
        HStack(spacing: 12) {
            toggleButton(
                icon: webcamEnabled ? "video.fill" : "video.slash",
                label: "Cam",
                isActive: webcamEnabled,
                action: onToggleWebcam
            )
            toggleButton(
                icon: microphoneEnabled ? "mic.fill" : "mic.slash",
                label: "Mic",
                isActive: microphoneEnabled,
                action: onToggleMicrophone
            )
        }
        .frame(width: 100)
    }

    private func toggleButton(
        icon: String,
        label: String,
        isActive: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(isActive ? Color.accentColor : .secondary)
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview("Idle") {
    RecordingControlsView(
        state: .initial(),
        webcamEnabled: true,
        microphoneEnabled: true,
        onStart: {}, onStop: {}, onPause: {}, onResume: {},
        onToggleWebcam: {}, onToggleMicrophone: {}
    )
    .frame(width: 400)
}

#Preview("Recording") {
    RecordingControlsView(
        state: RecordingState(
            status: .recording(startedAt: Date()),
            configuration: .default,
            elapsedTime: 42
        ),
        webcamEnabled: true,
        microphoneEnabled: false,
        onStart: {}, onStop: {}, onPause: {}, onResume: {},
        onToggleWebcam: {}, onToggleMicrophone: {}
    )
    .frame(width: 400)
}
