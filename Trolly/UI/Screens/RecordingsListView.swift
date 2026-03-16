import SwiftUI

struct RecordingsListView: View {
    @Environment(AppState.self) private var appState

    @State private var playingRecording: RecordingMetadata?

    var body: some View {
        VStack(spacing: 0) {
            if let recording = playingRecording {
                playerHeader(recording: recording)
                Divider()
                VideoPlayerView(recording: recording)
            } else {
                listHeader
                Divider()
                listContent
            }
        }
        .task {
            await appState.loadRecordings()
        }
    }

    // MARK: - List Header

    private var listHeader: some View {
        HStack {
            Text("Recordings")
                .font(.system(.headline, design: .rounded, weight: .bold))
            Spacer()
            if appState.isLoadingRecordings {
                ProgressView()
                    .controlSize(.small)
            }
            Button {
                Task { await appState.loadRecordings() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12))
            }
            .buttonStyle(.borderless)
            .help("Refresh")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
    }

    // MARK: - Player Header

    private func playerHeader(recording: RecordingMetadata) -> some View {
        HStack {
            Button {
                playingRecording = nil
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Back")
                        .font(.system(.subheadline, weight: .medium))
                }
            }
            .buttonStyle(.borderless)

            Spacer()

            Text(recording.fileURL.deletingPathExtension().lastPathComponent)
                .font(.system(.subheadline, weight: .medium))
                .lineLimit(1)

            Spacer()

            // Balance the back button
            Color.clear.frame(width: 50)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
    }

    // MARK: - List Content

    @ViewBuilder
    private var listContent: some View {
        if appState.recordings.isEmpty && !appState.isLoadingRecordings {
            emptyState
        } else {
            recordingsList
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "film.stack")
                .font(.system(size: 36))
                .foregroundStyle(.tertiary)
            Text("No recordings yet")
                .font(.callout.weight(.medium))
                .foregroundStyle(.secondary)
            Text("Your recordings will appear here.")
                .font(.caption)
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var recordingsList: some View {
        List {
            ForEach(appState.recordings) { recording in
                RecordingRowView(
                    recording: recording,
                    isTranscribing: appState.transcribingRecordingIDs.contains(recording.id),
                    hasTranscript: appState.transcribedRecordingIDs.contains(recording.id)
                )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        playingRecording = recording
                    }
                    .contextMenu {
                        transcribeContextMenuItem(for: recording)
                        Button("Show in Finder") {
                            NSWorkspace.shared.activateFileViewerSelecting([recording.fileURL])
                        }
                        Divider()
                        Button("Delete", role: .destructive) {
                            Task { await appState.deleteRecording(id: recording.id) }
                        }
                    }
            }
        }
        .listStyle(.inset)
    }

    @ViewBuilder
    private func transcribeContextMenuItem(for recording: RecordingMetadata) -> some View {
        let isTranscribing = appState.transcribingRecordingIDs.contains(recording.id)
        let hasTranscript = appState.transcribedRecordingIDs.contains(recording.id)

        if isTranscribing {
            Label("Transcribing...", systemImage: "waveform")
                .disabled(true)
        } else if hasTranscript {
            Button {
                Task { await appState.transcribeRecording(id: recording.id) }
            } label: {
                Label("Re-transcribe", systemImage: "arrow.clockwise")
            }
        } else {
            Button {
                Task { await appState.transcribeRecording(id: recording.id) }
            } label: {
                Label("Transcribe", systemImage: "text.bubble")
            }
        }
    }
}

// MARK: - Recording Row

struct RecordingRowView: View {
    let recording: RecordingMetadata
    var isTranscribing: Bool = false
    var hasTranscript: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            thumbnail
            details
            Spacer()
            transcriptionBadge
            meta
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var transcriptionBadge: some View {
        if isTranscribing {
            ProgressView()
                .controlSize(.small)
                .help("Transcribing...")
        } else if hasTranscript {
            Image(systemName: "text.bubble.fill")
                .font(.caption)
                .foregroundStyle(.blue)
                .help("Transcript available")
        }
    }

    private var thumbnail: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(.quaternary)
                .frame(width: 64, height: 40)
            Image(systemName: "play.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(.secondary)
        }
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(recording.fileURL.deletingPathExtension().lastPathComponent)
                .font(.system(.callout, weight: .medium))
                .lineLimit(1)
            HStack(spacing: 8) {
                Label(recording.sourceName, systemImage: "display")
                if recording.hasWebcam {
                    Image(systemName: "video.fill")
                }
                if recording.hasAudio {
                    Image(systemName: "mic.fill")
                }
            }
            .font(.caption2)
            .foregroundStyle(.tertiary)
        }
    }

    private var meta: some View {
        VStack(alignment: .trailing, spacing: 3) {
            Text(formattedDuration)
                .font(.system(.caption, design: .monospaced, weight: .medium))
                .foregroundStyle(.secondary)
            Text(formattedDate)
                .font(.caption2)
                .foregroundStyle(.tertiary)
            Text(formattedSize)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    private var formattedDuration: String {
        let total = Int(recording.duration)
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: recording.createdAt)
    }

    private var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: recording.fileSize)
    }
}
