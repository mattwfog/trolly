import SwiftUI

struct SourcePickerView: View {
    let displays: [DisplayInfo]
    let windows: [WindowInfo]
    let selectedSource: CaptureSource?
    let onSelect: (CaptureSource) -> Void

    var body: some View {
        Menu {
            if !displays.isEmpty {
                Section("Displays") {
                    ForEach(displays) { display in
                        displayMenuItem(display)
                    }
                }
            }

            if !windows.isEmpty {
                Section("Windows") {
                    ForEach(windows) { window in
                        windowMenuItem(window)
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                selectedIcon
                Text(selectedLabel)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(maxWidth: 250)
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var selectedIcon: some View {
        if let source = selectedSource {
            switch source {
            case .fullScreen:
                Image(systemName: "display")
            case .window:
                Image(systemName: "macwindow")
            case .region:
                Image(systemName: "rectangle.dashed")
            }
        } else {
            Image(systemName: "display")
                .foregroundStyle(.secondary)
        }
    }

    private var selectedLabel: String {
        selectedSource?.displayName ?? "Select source..."
    }

    private func displayMenuItem(_ display: DisplayInfo) -> some View {
        let source = CaptureSource.fullScreen(display: display)
        let isSelected = selectedSource == source

        return Button(action: { onSelect(source) }) {
            HStack {
                Label(
                    "\(display.displayName) (\(display.width)x\(display.height))",
                    systemImage: "display"
                )
                if isSelected {
                    Spacer()
                    Image(systemName: "checkmark")
                }
            }
        }
    }

    private func windowMenuItem(_ window: WindowInfo) -> some View {
        let source = CaptureSource.window(window: window)
        let isSelected = selectedSource == source

        return Button(action: { onSelect(source) }) {
            HStack {
                Label(
                    "\(window.applicationName) - \(window.title)",
                    systemImage: "macwindow"
                )
                if isSelected {
                    Spacer()
                    Image(systemName: "checkmark")
                }
            }
        }
    }
}

#Preview {
    SourcePickerView(
        displays: [
            DisplayInfo(id: 1, displayName: "Built-in Display", width: 2560, height: 1600)
        ],
        windows: [
            WindowInfo(
                id: 100,
                title: "Document.swift",
                applicationName: "Xcode",
                frame: CGRect(x: 0, y: 0, width: 1200, height: 800)
            )
        ],
        selectedSource: nil,
        onSelect: { _ in }
    )
    .padding()
}
