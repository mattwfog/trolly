import SwiftUI

struct TeleprompterSettingsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        let settings = appState.settingsStore.teleprompterSettings

        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Teleprompter")
            settingsContent(settings)
            Divider().padding(.vertical, 4)
            resetButton
        }
        .padding(12)
        .frame(width: 260)
    }

    private func settingsContent(_ settings: TeleprompterSettings) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            settingsRow("Font Size") {
                Picker("", selection: Binding(
                    get: { settings.fontSize },
                    set: { update(settings.withFontSize($0)) }
                )) {
                    ForEach(TeleprompterFontSize.allCases, id: \.self) { size in
                        Text(size.label).tag(size)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .frame(width: 160)
            }

            settingsRow("Speed") {
                Picker("", selection: Binding(
                    get: { settings.scrollSpeed },
                    set: { update(settings.withScrollSpeed($0)) }
                )) {
                    ForEach(ScrollSpeed.allCases, id: \.self) { speed in
                        Text(speed.label).tag(speed)
                    }
                }
                .labelsHidden()
                .frame(width: 100)
            }

            settingsRow("Text") {
                Picker("", selection: Binding(
                    get: { settings.textColor },
                    set: { update(settings.withTextColor($0)) }
                )) {
                    ForEach(TeleprompterColor.allCases, id: \.self) { color in
                        Text(color.label).tag(color)
                    }
                }
                .labelsHidden()
                .frame(width: 100)
            }

            settingsRow("Background") {
                Picker("", selection: Binding(
                    get: { settings.backgroundColor },
                    set: { update(settings.withBackgroundColor($0)) }
                )) {
                    ForEach(TeleprompterColor.allCases, id: \.self) { color in
                        Text(color.label).tag(color)
                    }
                }
                .labelsHidden()
                .frame(width: 100)
            }

            settingsRow("BG Opacity") {
                HStack(spacing: 4) {
                    Slider(
                        value: Binding(
                            get: { settings.backgroundOpacity },
                            set: { update(settings.withBackgroundOpacity($0)) }
                        ),
                        in: 0.3...1.0,
                        step: 0.05
                    )
                    .frame(width: 90)
                    Text("\(Int(settings.backgroundOpacity * 100))%")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(.tertiary)
                        .frame(width: 32, alignment: .trailing)
                }
            }

            settingsToggle("Mirror", isOn: settings.mirrorHorizontally) {
                update(settings.withMirrorHorizontally($0))
            }

            settingsToggle("Countdown", isOn: settings.showCountdown) {
                update(settings.withShowCountdown($0))
            }

            if settings.showCountdown {
                settingsRow("Seconds") {
                    Stepper(
                        "\(settings.countdownSeconds)s",
                        value: Binding(
                            get: { settings.countdownSeconds },
                            set: { update(settings.withCountdownSeconds($0)) }
                        ),
                        in: 1...10
                    )
                    .frame(width: 100)
                }
            }
        }
    }

    // MARK: - Reset

    private var resetButton: some View {
        HStack {
            Spacer()
            Button("Reset to Defaults") {
                appState.settingsStore.resetTeleprompterSettings()
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

    private func update(_ settings: TeleprompterSettings) {
        appState.settingsStore.updateTeleprompterSettings(settings)
    }
}
