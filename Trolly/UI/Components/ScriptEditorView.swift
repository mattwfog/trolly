import SwiftUI

struct ScriptEditorView: View {
    let existingScript: Script?
    let onSave: (Script) -> Void
    let onCancel: () -> Void

    @State private var title: String
    @State private var content: String

    init(
        existingScript: Script? = nil,
        onSave: @escaping (Script) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.existingScript = existingScript
        self.onSave = onSave
        self.onCancel = onCancel
        _title = State(initialValue: existingScript?.title ?? "")
        _content = State(initialValue: existingScript?.content ?? "")
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            editorArea
            Divider()
            footer
        }
        .frame(minWidth: 360, minHeight: 300)
    }

    private var header: some View {
        HStack {
            Text(existingScript == nil ? "New Script" : "Edit Script")
                .font(.system(.subheadline, weight: .semibold))
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
    }

    private var editorArea: some View {
        VStack(spacing: 8) {
            TextField("Script title", text: $title)
                .textFieldStyle(.roundedBorder)
                .font(.system(.callout, weight: .medium))

            TextEditor(text: $content)
                .font(.system(.body))
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.quaternary)
                )
                .overlay(placeholderOverlay)
        }
        .padding(12)
    }

    @ViewBuilder
    private var placeholderOverlay: some View {
        if content.isEmpty {
            VStack {
                HStack {
                    Text("Write your script here...")
                        .foregroundStyle(.tertiary)
                        .font(.system(.body))
                        .padding(.leading, 13)
                        .padding(.top, 16)
                    Spacer()
                }
                Spacer()
            }
            .allowsHitTesting(false)
        }
    }

    private var footer: some View {
        HStack {
            Button("Cancel", action: onCancel)
                .buttonStyle(.borderless)

            Spacer()

            Text("\(wordCount) words")
                .font(.caption2)
                .foregroundStyle(.tertiary)

            Button("Save") {
                save()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty
                      || content.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
    }

    // MARK: - Private

    private var wordCount: Int {
        content.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)

        if let existing = existingScript {
            let updated = existing
                .withTitle(trimmedTitle)
                .withContent(trimmedContent)
            onSave(updated)
        } else {
            let script = Script.create(title: trimmedTitle, content: trimmedContent)
            onSave(script)
        }
    }
}
