import SwiftUI

struct CursorTrackerSettingsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        let settings = appState.settingsStore.cursorTrackerSettings

        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Cursor Highlight")
            settingsContent(settings)
            Divider().padding(.vertical, 4)
            resetButton
        }
        .padding(12)
        .frame(width: 260)
    }

    private func settingsContent(_ settings: CursorTrackerSettings) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            settingsToggle("Enabled", isOn: settings.enabled) {
                update(settings.withEnabled($0))
            }

            if settings.enabled {
                settingsRow("Style") {
                    Picker("", selection: Binding(
                        get: { settings.highlightStyle },
                        set: { update(settings.withHighlightStyle($0)) }
                    )) {
                        ForEach(CursorHighlightStyle.allCases, id: \.self) { style in
                            Label(style.label, systemImage: style.icon).tag(style)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .frame(width: 120)
                }

                settingsRow("Size") {
                    HStack(spacing: 4) {
                        Slider(
                            value: Binding(
                                get: { settings.ringSize },
                                set: { update(settings.withRingSize($0)) }
                            ),
                            in: 20...100,
                            step: 5
                        )
                        .frame(width: 90)
                        Text("\(Int(settings.ringSize))px")
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(.tertiary)
                            .frame(width: 36, alignment: .trailing)
                    }
                }

                settingsRow("Color") {
                    Picker("", selection: Binding(
                        get: { settings.highlightColor },
                        set: { update(settings.withHighlightColor($0)) }
                    )) {
                        ForEach(CursorHighlightColor.allCases, id: \.self) { color in
                            Text(color.label).tag(color)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 100)
                }

                settingsRow("Opacity") {
                    HStack(spacing: 4) {
                        Slider(
                            value: Binding(
                                get: { settings.highlightOpacity },
                                set: { update(settings.withHighlightOpacity($0)) }
                            ),
                            in: 0.1...1.0,
                            step: 0.1
                        )
                        .frame(width: 90)
                        Text("\(Int(settings.highlightOpacity * 100))%")
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(.tertiary)
                            .frame(width: 32, alignment: .trailing)
                    }
                }

                Divider().padding(.vertical, 2)

                settingsToggle("Click ripple", isOn: settings.clickEffectEnabled) {
                    update(settings.withClickEffectEnabled($0))
                }

                if settings.clickEffectEnabled {
                    settingsRow("Click color") {
                        Picker("", selection: Binding(
                            get: { settings.clickColor },
                            set: { update(settings.withClickColor($0)) }
                        )) {
                            ForEach(CursorHighlightColor.allCases, id: \.self) { color in
                                Text(color.label).tag(color)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 100)
                    }
                }
            }
        }
    }

    // MARK: - Reset

    private var resetButton: some View {
        HStack {
            Spacer()
            Button("Reset to Defaults") {
                appState.settingsStore.resetCursorTrackerSettings()
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

    private func update(_ settings: CursorTrackerSettings) {
        appState.settingsStore.updateCursorTrackerSettings(settings)
    }
}
