import SwiftUI

struct ScriptListView: View {
    @Environment(AppState.self) private var appState

    let onSelect: (Script) -> Void
    let onDismiss: () -> Void

    @State private var scripts: [Script] = []
    @State private var isLoading: Bool = false
    @State private var editingScript: Script?
    @State private var showEditor: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
        }
        .frame(minWidth: 300, idealWidth: 340, minHeight: 250)
        .sheet(isPresented: $showEditor) {
            ScriptEditorView(
                existingScript: editingScript,
                onSave: { script in
                    Task { await saveScript(script) }
                    showEditor = false
                    editingScript = nil
                },
                onCancel: {
                    showEditor = false
                    editingScript = nil
                }
            )
        }
        .task {
            await loadScripts()
        }
    }

    private var header: some View {
        HStack {
            Text("Scripts")
                .font(.system(.subheadline, weight: .semibold))
            Spacer()
            Button {
                editingScript = nil
                showEditor = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 12))
            }
            .buttonStyle(.borderless)
            .help("New script")
            Button("Done", action: onDismiss)
                .buttonStyle(.borderless)
                .font(.caption)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            VStack {
                Spacer()
                ProgressView()
                Spacer()
            }
            .frame(maxWidth: .infinity)
        } else if scripts.isEmpty {
            emptyState
        } else {
            scriptsList
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "doc.text")
                .font(.system(size: 32))
                .foregroundStyle(.tertiary)
            Text("No scripts yet")
                .font(.callout.weight(.medium))
                .foregroundStyle(.secondary)
            Button("Create Script") {
                editingScript = nil
                showEditor = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var scriptsList: some View {
        List {
            ForEach(scripts) { script in
                ScriptRowView(script: script)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onSelect(script)
                    }
                    .contextMenu {
                        Button("Edit") {
                            editingScript = script
                            showEditor = true
                        }
                        Divider()
                        Button("Delete", role: .destructive) {
                            Task { await deleteScript(script) }
                        }
                    }
            }
        }
        .listStyle(.inset)
    }

    // MARK: - Actions

    private func loadScripts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            scripts = try await appState.scriptStorage.fetchAll()
        } catch {
            appState.setError(error.localizedDescription)
        }
    }

    private func saveScript(_ script: Script) async {
        do {
            try await appState.scriptStorage.save(script: script)
            await loadScripts()
        } catch {
            appState.setError(error.localizedDescription)
        }
    }

    private func deleteScript(_ script: Script) async {
        do {
            try appState.scriptStorage.delete(id: script.id)
            scripts = scripts.filter { $0.id != script.id }
        } catch {
            appState.setError(error.localizedDescription)
        }
    }
}

// MARK: - Script Row

struct ScriptRowView: View {
    let script: Script

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(script.title)
                .font(.system(.callout, weight: .medium))
                .lineLimit(1)
            HStack(spacing: 8) {
                Text("\(wordCount) words")
                Text(formattedDate)
            }
            .font(.caption2)
            .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }

    private var wordCount: Int {
        script.content.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: script.updatedAt)
    }
}
