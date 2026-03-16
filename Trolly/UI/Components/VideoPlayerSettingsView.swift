import SwiftUI

struct VideoPlayerSettingsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        let settings = appState.settingsStore.videoPlayerSettings

        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Transcript")
            transcriptSection(settings)
            Divider().padding(.vertical, 4)
            sectionHeader("Playback")
            playbackSection(settings)
            Divider().padding(.vertical, 4)
            resetButton
        }
        .padding(12)
        .frame(width: 260)
    }

    // MARK: - Transcript

    private func transcriptSection(_ settings: VideoPlayerSettings) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            settingsRow("Position") {
                Picker("", selection: Binding(
                    get: { settings.transcriptPosition },
                    set: { update(settings.withTranscriptPosition($0)) }
                )) {
                    ForEach(TranscriptPanelPosition.allCases, id: \.self) { pos in
                        Label(pos.label, systemImage: pos.icon).tag(pos)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .frame(width: 150)
            }

            settingsRow("Panel Size") {
                Picker("", selection: Binding(
                    get: { settings.transcriptPanelSize },
                    set: { update(settings.withTranscriptPanelSize($0)) }
                )) {
                    ForEach(TranscriptPanelSize.allCases, id: \.self) { size in
                        Text(size.label).tag(size)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .frame(width: 150)
            }

            settingsRow("Font Size") {
                Picker("", selection: Binding(
                    get: { settings.transcriptFontSize },
                    set: { update(settings.withTranscriptFontSize($0)) }
                )) {
                    ForEach(TranscriptFontSize.allCases, id: \.self) { size in
                        Text(size.label).tag(size)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .frame(width: 150)
            }

            settingsRow("Timestamps") {
                Picker("", selection: Binding(
                    get: { settings.timestampFormat },
                    set: { update(settings.withTimestampFormat($0)) }
                )) {
                    ForEach(TimestampFormat.allCases, id: \.self) { fmt in
                        Text(fmt.label).tag(fmt)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .frame(width: 100)
            }

            settingsToggle("Show Timestamps", isOn: settings.transcriptShowTimestamps) {
                update(settings.withTranscriptShowTimestamps($0))
            }

            settingsToggle("Auto-scroll", isOn: settings.transcriptAutoScroll) {
                update(settings.withTranscriptAutoScroll($0))
            }

            settingsToggle("Show by Default", isOn: settings.transcriptVisibleByDefault) {
                update(settings.withTranscriptVisibleByDefault($0))
            }
        }
    }

    // MARK: - Playback

    private func playbackSection(_ settings: VideoPlayerSettings) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            settingsRow("Speed") {
                Picker("", selection: Binding(
                    get: { settings.playbackRate },
                    set: { update(settings.withPlaybackRate($0)) }
                )) {
                    ForEach(PlaybackRate.allCases, id: \.self) { rate in
                        Text(rate.label).tag(rate)
                    }
                }
                .labelsHidden()
                .frame(width: 80)
            }

            settingsToggle("Loop", isOn: settings.loopPlayback) {
                update(settings.withLoopPlayback($0))
            }

            settingsToggle("Auto-play", isOn: settings.autoPlay) {
                update(settings.withAutoPlay($0))
            }
        }
    }

    // MARK: - Reset

    private var resetButton: some View {
        HStack {
            Spacer()
            Button("Reset to Defaults") {
                appState.settingsStore.resetVideoPlayerSettings()
            }
            .font(.caption)
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(.caption, weight: .semibold))
            .foregroundStyle(.secondary)
            .padding(.bottom, 6)
    }

    private func settingsRow<Content: View>(
        _ label: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack {
            Text(label)
                .font(.system(.caption))
            Spacer()
            content()
        }
    }

    private func settingsToggle(
        _ label: String,
        isOn: Bool,
        onChange: @escaping (Bool) -> Void
    ) -> some View {
        Toggle(label, isOn: Binding(
            get: { isOn },
            set: onChange
        ))
        .toggleStyle(.switch)
        .controlSize(.mini)
        .font(.system(.caption))
    }

    private func update(_ settings: VideoPlayerSettings) {
        appState.settingsStore.updateVideoPlayerSettings(settings)
    }
}
