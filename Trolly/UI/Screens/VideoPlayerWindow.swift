import SwiftUI
import AVKit
import Combine

struct VideoPlayerView: View {
    let recording: RecordingMetadata

    @Environment(AppState.self) private var appState

    @State private var player: AVPlayer?
    @State private var transcript: Transcript?
    @State private var currentTime: TimeInterval = 0
    @State private var showTranscript: Bool = true
    @State private var showSettings: Bool = false
    @State private var timeObserver: Any?
    @State private var loopObserver: (any NSObjectProtocol)?

    private var settings: VideoPlayerSettings {
        appState.settingsStore.videoPlayerSettings
    }

    var body: some View {
        VStack(spacing: 0) {
            mainContent
            Divider()
            infoBar
        }
        .frame(minWidth: 480, minHeight: 340)
        .onAppear {
            showTranscript = settings.transcriptVisibleByDefault
            let newPlayer = AVPlayer(url: recording.fileURL)
            player = newPlayer
            applyPlaybackRate(to: newPlayer)
            setupTimeObserver(for: newPlayer)
            setupLoopObserver(for: newPlayer)
            if settings.autoPlay {
                newPlayer.play()
            }
            Task { await loadTranscript() }
        }
        .onDisappear {
            removeTimeObserver()
            removeLoopObserver()
            player?.pause()
            player = nil
        }
        .onChange(of: settings.playbackRate) { _, _ in
            if let player { applyPlaybackRate(to: player) }
        }
        .onChange(of: settings.loopPlayback) { _, _ in
            if let player {
                removeLoopObserver()
                setupLoopObserver(for: player)
            }
        }
    }

    // MARK: - Main Content

    @ViewBuilder
    private var mainContent: some View {
        let hasTranscript = transcript != nil && showTranscript
        switch settings.transcriptPosition {
        case .left where hasTranscript:
            HSplitView {
                transcriptArea
                    .frame(
                        minWidth: 160,
                        idealWidth: settings.transcriptPanelSize.sideWidth
                    )
                playerArea
                    .frame(minWidth: 320)
            }
        case .right where hasTranscript:
            HSplitView {
                playerArea
                    .frame(minWidth: 320)
                transcriptArea
                    .frame(
                        minWidth: 160,
                        idealWidth: settings.transcriptPanelSize.sideWidth
                    )
            }
        case .bottom where hasTranscript:
            VSplitView {
                playerArea
                    .frame(minHeight: 200)
                transcriptArea
                    .frame(
                        minHeight: 80,
                        idealHeight: settings.transcriptPanelSize.bottomHeight
                    )
            }
        default:
            playerArea
        }
    }

    private var playerArea: some View {
        Group {
            if let player {
                AVPlayerViewRepresentable(player: player)
            } else {
                ZStack {
                    Rectangle().fill(.black)
                    ProgressView()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var transcriptArea: some View {
        if let transcript {
            VStack(spacing: 0) {
                HStack {
                    Text("Transcript")
                        .font(.system(.caption, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.bar)

                Divider()

                TranscriptPanelView(
                    transcript: transcript,
                    currentTime: currentTime,
                    settings: settings
                )
            }
        }
    }

    // MARK: - Info Bar

    private var infoBar: some View {
        HStack(spacing: 12) {
            Label(formattedDuration, systemImage: "clock")
            Label(recording.sourceName, systemImage: "display")
            if recording.hasWebcam {
                Label("Webcam", systemImage: "video.fill")
            }
            if recording.hasAudio {
                Label("Audio", systemImage: "mic.fill")
            }

            Spacer()

            if settings.playbackRate != .normal {
                Text(settings.playbackRate.label)
                    .font(.system(.caption2, design: .monospaced, weight: .medium))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 3))
            }

            if transcript != nil {
                Button {
                    showTranscript.toggle()
                } label: {
                    Image(systemName: showTranscript ? "text.bubble.fill" : "text.bubble")
                }
                .buttonStyle(.borderless)
                .help(showTranscript ? "Hide transcript" : "Show transcript")
            }

            Button {
                showSettings.toggle()
            } label: {
                Image(systemName: "gearshape")
            }
            .buttonStyle(.borderless)
            .help("Player settings")
            .popover(isPresented: $showSettings, arrowEdge: .bottom) {
                VideoPlayerSettingsView()
            }

            Label(formattedSize, systemImage: "doc")

            Button("Show in Finder") {
                NSWorkspace.shared.activateFileViewerSelecting([recording.fileURL])
            }
            .buttonStyle(.borderless)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
    }

    // MARK: - Private

    private func loadTranscript() async {
        transcript = await appState.loadTranscript(for: recording)
    }

    private func applyPlaybackRate(to player: AVPlayer) {
        player.rate = settings.playbackRate.rate
    }

    private func setupTimeObserver(for player: AVPlayer) {
        let interval = CMTime(seconds: 0.25, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: interval,
            queue: .main
        ) { time in
            currentTime = time.seconds
        }
    }

    private func removeTimeObserver() {
        if let observer = timeObserver, let player {
            player.removeTimeObserver(observer)
        }
        timeObserver = nil
    }

    private func setupLoopObserver(for player: AVPlayer) {
        guard settings.loopPlayback else { return }
        loopObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            player.seek(to: .zero)
            player.play()
        }
    }

    private func removeLoopObserver() {
        if let observer = loopObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        loopObserver = nil
    }

    private var formattedDuration: String {
        let total = Int(recording.duration)
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }

    private var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: recording.fileSize)
    }
}

// MARK: - AVPlayerView wrapper (avoids VideoPlayer metadata crash in SPM)

struct AVPlayerViewRepresentable: NSViewRepresentable {
    let player: AVPlayer

    func makeNSView(context: Context) -> AVPlayerView {
        let view = AVPlayerView()
        view.player = player
        view.controlsStyle = .inline
        view.showsFullScreenToggleButton = true
        return view
    }

    func updateNSView(_ nsView: AVPlayerView, context: Context) {
        nsView.player = player
    }
}
