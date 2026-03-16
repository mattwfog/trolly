import SwiftUI

@main
struct TrollyApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 460, height: 480)
    }
}

struct ContentView: View {
    @Environment(AppState.self) private var appState

    @State private var selectedTab: AppTab = .record

    var body: some View {
        VStack(spacing: 0) {
            tabContent
            Divider()
            tabBar
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .record:
            MainRecordingView(onRecordingSaved: {
                Task { await appState.loadRecordings() }
            })
        case .library:
            RecordingsListView()
        }
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            tabButton(.record)
            tabButton(.library)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(.bar)
    }

    private func tabButton(_ tab: AppTab) -> some View {
        Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 3) {
                Image(systemName: tab.icon)
                    .font(.system(size: 16))
                Text(tab.label)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(selectedTab == tab ? Color.accentColor : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

enum AppTab {
    case record
    case library

    var icon: String {
        switch self {
        case .record: return "record.circle"
        case .library: return "film.stack"
        }
    }

    var label: String {
        switch self {
        case .record: return "Record"
        case .library: return "Library"
        }
    }
}
