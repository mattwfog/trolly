import SwiftUI

struct WebcamSettingsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        let settings = appState.settingsStore.webcamOverlaySettings

        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Webcam Overlay")
            settingsContent(settings)
            Divider().padding(.vertical, 4)
            resetButton
        }
        .padding(12)
        .frame(width: 260)
    }

    private func settingsContent(_ settings: WebcamOverlaySettings) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            settingsRow("Position") {
                Picker("", selection: Binding(
                    get: { settings.position },
                    set: { update(settings.withPosition($0)) }
                )) {
                    ForEach(WebcamPosition.allCases, id: \.self) { pos in
                        Text(positionLabel(pos)).tag(pos)
                    }
                }
                .labelsHidden()
                .frame(width: 130)
            }

            settingsRow("Size") {
                Picker("", selection: Binding(
                    get: { settings.size },
                    set: { update(settings.withSize($0)) }
                )) {
                    ForEach(WebcamSize.allCases, id: \.self) { size in
                        Text(sizeLabel(size)).tag(size)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .frame(width: 150)
            }

            settingsRow("Shape") {
                Picker("", selection: Binding(
                    get: { settings.shape },
                    set: { update(settings.withShape($0)) }
                )) {
                    ForEach(WebcamShape.allCases, id: \.self) { shape in
                        Label(shape.label, systemImage: shape.icon).tag(shape)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .frame(width: 150)
            }

            settingsRow("Opacity") {
                HStack(spacing: 4) {
                    Slider(
                        value: Binding(
                            get: { settings.opacity },
                            set: { update(settings.withOpacity($0)) }
                        ),
                        in: 0.3...1.0,
                        step: 0.1
                    )
                    .frame(width: 100)

                    Text("\(Int(settings.opacity * 100))%")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(.tertiary)
                        .frame(width: 32, alignment: .trailing)
                }
            }

            settingsToggle("Border", isOn: settings.showBorder) {
                update(settings.withShowBorder($0))
            }
        }
    }

    // MARK: - Reset

    private var resetButton: some View {
        HStack {
            Spacer()
            Button("Reset to Defaults") {
                appState.settingsStore.resetWebcamOverlaySettings()
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

    private func update(_ settings: WebcamOverlaySettings) {
        appState.settingsStore.updateWebcamOverlaySettings(settings)
    }

    private func positionLabel(_ pos: WebcamPosition) -> String {
        switch pos {
        case .topLeft: return "Top Left"
        case .topRight: return "Top Right"
        case .bottomLeft: return "Bottom Left"
        case .bottomRight: return "Bottom Right"
        }
    }

    private func sizeLabel(_ size: WebcamSize) -> String {
        switch size {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        }
    }
}
