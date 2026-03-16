import SwiftUI

struct StatusBadgeView: View {
    let status: RecordingStatus

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            Text(statusText)
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .textCase(.uppercase)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.15))
        .clipShape(Capsule())
    }

    private var statusText: String {
        switch status {
        case .idle: return "Ready"
        case .preparing: return "Preparing..."
        case .recording: return "Recording"
        case .paused: return "Paused"
        case .stopping: return "Saving..."
        case .failed: return "Error"
        }
    }

    private var statusColor: Color {
        switch status {
        case .idle: return .green
        case .preparing: return .orange
        case .recording: return .red
        case .paused: return .yellow
        case .stopping: return .orange
        case .failed: return .red
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        StatusBadgeView(status: .idle)
        StatusBadgeView(status: .preparing)
        StatusBadgeView(status: .recording(startedAt: Date()))
        StatusBadgeView(status: .paused(elapsed: 10))
        StatusBadgeView(status: .stopping)
    }
    .padding()
}
