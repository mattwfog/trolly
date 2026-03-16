import SwiftUI

struct SourceSwitcherSheet: View {
    @Environment(AppState.self) private var appState

    let currentSource: CaptureSource?
    let onSwitch: (CaptureSource) -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            SourceSelectionView(
                displays: appState.availableDisplays,
                windows: appState.availableWindows,
                selectedSource: currentSource,
                isLoading: appState.isLoadingSources,
                onSelect: onSwitch,
                onRefresh: {
                    Task { await appState.loadAvailableSources() }
                },
                onSelectRegion: {
                    Task { await selectRegion() }
                }
            )
        }
        .frame(minWidth: 320, idealWidth: 360, minHeight: 280)
    }

    private var header: some View {
        HStack {
            Text("Switch Recording Source")
                .font(.system(.subheadline, weight: .semibold))
            Spacer()
            Button("Done", action: onDismiss)
                .buttonStyle(.borderless)
                .font(.caption)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
    }

    private func selectRegion() async {
        guard let display = appState.availableDisplays.first else {
            appState.setError("No displays available for region selection.")
            return
        }

        onDismiss()

        guard let rect = await RegionSelectionWindow.selectRegion(on: display) else {
            return
        }

        let source = CaptureSource.region(display: display, rect: rect)
        onSwitch(source)
    }
}
