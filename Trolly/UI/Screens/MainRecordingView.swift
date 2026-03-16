import SwiftUI

struct MainRecordingView: View {
    @Environment(AppState.self) private var appState

    var onRecordingSaved: (() -> Void)?

    @State private var selectedSource: CaptureSource?
    @State private var configuration: RecordingConfiguration = .default
    @State private var lastSavedURL: URL?
    @State private var showWebcamSettings: Bool = false
    @State private var showCursorSettings: Bool = false
    @State private var showScriptList: Bool = false
    @State private var showTeleprompterSettings: Bool = false
    @State private var showSourceSwitcher: Bool = false

    private var coordinator: RecordingCoordinator {
        appState.recordingCoordinator
    }

    var body: some View {
        VStack(spacing: 0) {
            titleBar
            Divider()
            errorBanner
            content
        }
        .frame(minWidth: 420, idealWidth: 440, minHeight: 520)
        .task {
            await appState.loadAvailableSources()
        }
    }

    // MARK: - Title Bar

    private var titleBar: some View {
        HStack {
            Text("Trolly")
                .font(.system(.headline, design: .rounded, weight: .bold))
            Spacer()
            scriptButton
            Button {
                showCursorSettings.toggle()
            } label: {
                Image(systemName: appState.settingsStore.cursorTrackerSettings.enabled
                      ? "cursorarrow.click.badge.clock" : "cursorarrow.click.2")
                    .font(.system(size: 12))
            }
            .buttonStyle(.borderless)
            .help("Cursor highlight settings")
            .popover(isPresented: $showCursorSettings, arrowEdge: .bottom) {
                CursorTrackerSettingsView()
            }
            Button {
                showWebcamSettings.toggle()
            } label: {
                Image(systemName: "video.badge.ellipsis")
                    .font(.system(size: 12))
            }
            .buttonStyle(.borderless)
            .help("Webcam settings")
            .popover(isPresented: $showWebcamSettings, arrowEdge: .bottom) {
                WebcamSettingsView()
            }
            if appState.activeScript != nil {
                Button {
                    showTeleprompterSettings.toggle()
                } label: {
                    Image(systemName: "textformat.size")
                        .font(.system(size: 12))
                }
                .buttonStyle(.borderless)
                .help("Teleprompter settings")
                .popover(isPresented: $showTeleprompterSettings, arrowEdge: .bottom) {
                    TeleprompterSettingsView()
                }
            }
            StatusBadgeView(status: coordinator.state.status)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
    }

    // MARK: - Error Banner

    @ViewBuilder
    private var errorBanner: some View {
        if let message = appState.errorMessage {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.white)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                Spacer()
                Button {
                    appState.clearError()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.red.gradient)
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if coordinator.state.isIdle {
            idleContent
        } else {
            recordingContent
        }
    }

    // MARK: - Idle Content

    private var idleContent: some View {
        VStack(spacing: 0) {
            savedBanner
            activeScriptBanner

            SourceSelectionView(
                displays: appState.availableDisplays,
                windows: appState.availableWindows,
                selectedSource: selectedSource,
                isLoading: appState.isLoadingSources,
                onSelect: { source in
                    selectedSource = source
                    configuration = configuration.withCaptureSource(source)
                    lastSavedURL = nil
                    Task { await appState.capturePreviewViewModel.startPreview(for: source) }
                },
                onRefresh: {
                    Task { await appState.loadAvailableSources() }
                },
                onSelectRegion: {
                    Task { await selectRegion() }
                }
            )

            if selectedSource != nil {
                CapturePreviewView(
                    previewImage: appState.capturePreviewViewModel.previewImage,
                    isLoading: appState.capturePreviewViewModel.isLoading,
                    sourceName: selectedSource?.displayName ?? "",
                    aspectRatio: selectedSource?.aspectRatio ?? (16.0 / 9.0)
                )
            }

            Divider()

            idleFooter
        }
    }

    @ViewBuilder
    private var savedBanner: some View {
        if let url = lastSavedURL {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Saved to \(url.lastPathComponent)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Reveal") {
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                }
                .buttonStyle(.borderless)
                .font(.caption)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.green.opacity(0.08))
        }
    }

    @ViewBuilder
    private var activeScriptBanner: some View {
        if let script = appState.activeScript {
            HStack(spacing: 8) {
                Image(systemName: "doc.text.fill")
                    .foregroundStyle(.blue)
                VStack(alignment: .leading, spacing: 1) {
                    Text(script.title)
                        .font(.caption.weight(.medium))
                    Text("Script loaded — will show as teleprompter during recording")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    appState.setActiveScript(nil)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Remove script")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.blue.opacity(0.08))
        }
    }

    private var idleFooter: some View {
        VStack(spacing: 12) {
            if selectedSource != nil {
                HStack(spacing: 4) {
                    Image(systemName: "display")
                        .font(.caption2)
                    Text(selectedSource?.displayName ?? "")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }

            RecordingControlsView(
                state: coordinator.state,
                webcamEnabled: configuration.webcamEnabled,
                microphoneEnabled: configuration.microphoneEnabled,
                onStart: { startRecording() },
                onStop: {},
                onPause: {},
                onResume: {},
                onToggleWebcam: { toggleWebcam() },
                onToggleMicrophone: { toggleMicrophone() }
            )
        }
        .padding(.vertical, 8)
    }

    // MARK: - Recording Content

    private var recordingContent: some View {
        VStack(spacing: 0) {
            if let script = appState.activeScript {
                TeleprompterView(
                    script: script,
                    settings: appState.settingsStore.teleprompterSettings,
                    isRecording: coordinator.state.isRecording
                )
            } else {
                Spacer()
                recordingInfo
                TimerView(
                    elapsedTime: coordinator.state.elapsedTime,
                    isRecording: coordinator.state.isRecording
                )
                if coordinator.state.isPaused {
                    Text("Recording paused")
                        .font(.callout)
                        .foregroundStyle(.yellow)
                        .padding(.top, 4)
                }
                Spacer()
            }

            Divider()

            recordingFooter
        }
    }

    private var recordingFooter: some View {
        VStack(spacing: 0) {
            if appState.activeScript != nil {
                HStack(spacing: 12) {
                    TimerView(
                        elapsedTime: coordinator.state.elapsedTime,
                        isRecording: coordinator.state.isRecording
                    )
                    if coordinator.state.isPaused {
                        Text("Paused")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }
                }
                .padding(.vertical, 4)
                Divider()
            }

            HStack {
                Button {
                    showSourceSwitcher.toggle()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: iconName(for: coordinator.state.configuration.captureSource ?? .fullScreen(display: DisplayInfo(id: 0, displayName: "", width: 0, height: 0))))
                            .font(.system(size: 10))
                        Text("Switch")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
                .help("Switch recording source")
                .sheet(isPresented: $showSourceSwitcher) {
                    SourceSwitcherSheet(
                        currentSource: coordinator.state.configuration.captureSource,
                        onSwitch: { source in
                            Task {
                                await switchSource(to: source)
                                showSourceSwitcher = false
                            }
                        },
                        onDismiss: { showSourceSwitcher = false }
                    )
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(.bar.opacity(0.5))

            Divider()

            RecordingControlsView(
                state: coordinator.state,
                webcamEnabled: configuration.webcamEnabled,
                microphoneEnabled: configuration.microphoneEnabled,
                onStart: {},
                onStop: { stopRecording() },
                onPause: { pauseRecording() },
                onResume: { resumeRecording() },
                onToggleWebcam: { toggleWebcam() },
                onToggleMicrophone: { toggleMicrophone() }
            )
        }
    }

    private var recordingInfo: some View {
        HStack(spacing: 16) {
            if let source = selectedSource {
                HStack(spacing: 6) {
                    Image(systemName: iconName(for: source))
                        .font(.caption)
                    Text(source.displayName)
                        .font(.caption)
                        .lineLimit(1)
                }
                .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                if configuration.webcamEnabled {
                    Label("Cam", systemImage: "video.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                if configuration.microphoneEnabled {
                    Label("Mic", systemImage: "mic.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.bottom, 4)
    }

    // MARK: - Script Button

    private var scriptButton: some View {
        Button {
            showScriptList.toggle()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: appState.activeScript != nil ? "doc.text.fill" : "doc.text")
                    .font(.system(size: 12))
                if let script = appState.activeScript {
                    Text(script.title)
                        .font(.system(size: 10, weight: .medium))
                        .lineLimit(1)
                }
            }
        }
        .buttonStyle(.borderless)
        .help(appState.activeScript != nil ? "Change script" : "Load script")
        .sheet(isPresented: $showScriptList) {
            ScriptListView(
                onSelect: { script in
                    appState.setActiveScript(script)
                    showScriptList = false
                },
                onDismiss: { showScriptList = false }
            )
        }
    }

    // MARK: - Actions

    private func startRecording() {
        guard let source = selectedSource else {
            appState.setError("Select a screen or window to record.")
            return
        }
        let webcamSettings = appState.settingsStore.webcamOverlaySettings
        let config = configuration
            .withWebcamPosition(webcamSettings.position)
            .withWebcamSize(webcamSettings.size)
        Task {
            await appState.capturePreviewViewModel.stopPreview()
            do {
                try await coordinator.startRecording(with: config)
                appState.cursorTracker.start(
                    with: appState.settingsStore.cursorTrackerSettings
                )
            } catch {
                appState.setError(error.localizedDescription)
                await appState.capturePreviewViewModel.startPreview(for: source)
            }
        }
    }

    private func stopRecording() {
        Task {
            appState.cursorTracker.stop()
            do {
                let url = try await coordinator.stopRecording()
                lastSavedURL = url
                onRecordingSaved?()
                if let source = selectedSource {
                    await appState.capturePreviewViewModel.startPreview(for: source)
                }
            } catch {
                appState.setError(error.localizedDescription)
            }
        }
    }

    private func pauseRecording() {
        Task {
            do {
                try await coordinator.pauseRecording()
            } catch {
                appState.setError(error.localizedDescription)
            }
        }
    }

    private func resumeRecording() {
        Task {
            do {
                try await coordinator.resumeRecording()
            } catch {
                appState.setError(error.localizedDescription)
            }
        }
    }

    private func toggleWebcam() {
        configuration = configuration.withWebcam(enabled: !configuration.webcamEnabled)
    }

    private func toggleMicrophone() {
        configuration = configuration.withMicrophone(enabled: !configuration.microphoneEnabled)
    }

    private func switchSource(to source: CaptureSource) async {
        selectedSource = source
        configuration = configuration.withCaptureSource(source)
        await appState.switchRecordingSource(to: source)
    }

    private func iconName(for source: CaptureSource) -> String {
        switch source {
        case .fullScreen: return "display"
        case .window: return "macwindow"
        case .region: return "rectangle.dashed"
        }
    }

    private func selectRegion() async {
        guard let display = appState.availableDisplays.first else {
            appState.setError("No displays available for region selection.")
            return
        }

        await appState.capturePreviewViewModel.stopPreview()

        guard let rect = await RegionSelectionWindow.selectRegion(on: display) else {
            if let source = selectedSource {
                await appState.capturePreviewViewModel.startPreview(for: source)
            }
            return
        }

        let source = CaptureSource.region(display: display, rect: rect)
        selectedSource = source
        configuration = configuration.withCaptureSource(source)
        lastSavedURL = nil
        await appState.capturePreviewViewModel.startPreview(for: source)
    }
}

#Preview {
    MainRecordingView()
        .environment(AppState())
}
