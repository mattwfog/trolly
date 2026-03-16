import SwiftUI

struct SourceSelectionView: View {
    let displays: [DisplayInfo]
    let windows: [WindowInfo]
    let selectedSource: CaptureSource?
    let isLoading: Bool
    let onSelect: (CaptureSource) -> Void
    let onRefresh: () -> Void
    var onSelectRegion: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            sourceList
        }
    }

    private var header: some View {
        HStack {
            Text("Choose what to record")
                .font(.system(.subheadline, weight: .medium))
                .foregroundStyle(.secondary)
            Spacer()
            if let onSelectRegion {
                Button(action: onSelectRegion) {
                    Label("Select Region", systemImage: "rectangle.dashed")
                        .font(.system(size: 12))
                }
                .buttonStyle(.borderless)
                .help("Draw a region to record")
            }
            if isLoading {
                ProgressView()
                    .controlSize(.small)
            }
            Button(action: onRefresh) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12))
            }
            .buttonStyle(.borderless)
            .disabled(isLoading)
            .help("Refresh sources")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var sourceList: some View {
        List {
            if !displays.isEmpty {
                Section {
                    ForEach(displays) { display in
                        displayRow(display)
                    }
                } header: {
                    Label("Displays", systemImage: "display")
                        .font(.system(.caption, weight: .semibold))
                }
            }

            if !windows.isEmpty {
                Section {
                    ForEach(windows) { window in
                        windowRow(window)
                    }
                } header: {
                    Label("Windows", systemImage: "macwindow")
                        .font(.system(.caption, weight: .semibold))
                }
            }

            if displays.isEmpty && windows.isEmpty && !isLoading {
                ContentUnavailableView(
                    "No sources found",
                    systemImage: "display.trianglebadge.exclamationmark",
                    description: Text("Grant screen recording permission and try refreshing.")
                )
            }
        }
        .listStyle(.sidebar)
    }

    private func displayRow(_ display: DisplayInfo) -> some View {
        let source = CaptureSource.fullScreen(display: display)
        let isSelected = selectedSource == source

        return Button(action: { onSelect(source) }) {
            HStack(spacing: 10) {
                Image(systemName: "display")
                    .font(.system(size: 18))
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(display.displayName)
                        .font(.system(.body, weight: isSelected ? .semibold : .regular))
                    Text("\(display.width) x \(display.height)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.tint)
                }
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(
            isSelected
                ? Color.accentColor.opacity(0.1)
                : Color.clear
        )
    }

    private func windowRow(_ window: WindowInfo) -> some View {
        let source = CaptureSource.window(window: window)
        let isSelected = selectedSource == source

        return Button(action: { onSelect(source) }) {
            HStack(spacing: 10) {
                Image(systemName: "macwindow")
                    .font(.system(size: 18))
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(window.applicationName)
                        .font(.system(.body, weight: isSelected ? .semibold : .regular))
                    Text(window.title)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.tint)
                }
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(
            isSelected
                ? Color.accentColor.opacity(0.1)
                : Color.clear
        )
    }
}

#Preview {
    SourceSelectionView(
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
        isLoading: false,
        onSelect: { _ in },
        onRefresh: {}
    )
    .frame(width: 350, height: 400)
}
