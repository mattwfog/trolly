import SwiftUI

struct TimerView: View {
    let elapsedTime: TimeInterval
    let isRecording: Bool

    @State private var dotOpacity: Double = 1.0

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(.red)
                .frame(width: 12, height: 12)
                .opacity(dotOpacity)
                .onChange(of: isRecording, initial: true) { _, recording in
                    if recording {
                        startPulse()
                    } else {
                        withAnimation(.easeOut(duration: 0.2)) {
                            dotOpacity = 1.0
                        }
                    }
                }

            Text(formattedTime)
                .font(.system(size: 48, weight: .medium, design: .monospaced))
                .foregroundStyle(.primary)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private var formattedTime: String {
        let totalSeconds = Int(elapsedTime)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func startPulse() {
        withAnimation(
            .easeInOut(duration: 0.8)
            .repeatForever(autoreverses: true)
        ) {
            dotOpacity = 0.2
        }
    }
}

#Preview("Recording") {
    TimerView(elapsedTime: 125, isRecording: true)
}

#Preview("Paused") {
    TimerView(elapsedTime: 63, isRecording: false)
}
