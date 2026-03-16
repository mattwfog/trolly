import Foundation

final class ScriptStorageService: @unchecked Sendable {

    private let baseDirectory: URL
    private let fileManager: FileManager
    private let queue = DispatchQueue(label: "com.trolly.script-storage")
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()
    private let decoder = JSONDecoder()

    init(
        baseDirectory: URL? = nil,
        fileManager: FileManager = .default
    ) {
        self.baseDirectory = baseDirectory ?? Self.defaultDirectory
        self.fileManager = fileManager
    }

    static var defaultDirectory: URL {
        FileManager.default.urls(for: .moviesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Trolly", isDirectory: true)
            .appendingPathComponent("Scripts", isDirectory: true)
    }

    func save(script: Script) async throws {
        try ensureDirectoryExists()
        let url = fileURL(for: script.id)
        let data = try encoder.encode(script)
        let success = queue.sync {
            fileManager.createFile(atPath: url.path, contents: data)
        }
        guard success else {
            throw TrollyError.storageFailed(
                "Failed to write script to \(url.path)"
            )
        }
    }

    func load(id: UUID) async throws -> Script? {
        let url = fileURL(for: id)
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        let data = try Data(contentsOf: url)
        return try decoder.decode(Script.self, from: data)
    }

    func fetchAll() async throws -> [Script] {
        guard fileManager.fileExists(atPath: baseDirectory.path) else { return [] }
        let contents = try queue.sync {
            try fileManager.contentsOfDirectory(
                at: baseDirectory,
                includingPropertiesForKeys: nil
            )
        }
        let jsonFiles = contents.filter { $0.pathExtension == "json" }
        let scripts = jsonFiles.compactMap { url -> Script? in
            guard let data = try? Data(contentsOf: url) else { return nil }
            return try? decoder.decode(Script.self, from: data)
        }
        return scripts.sorted { $0.updatedAt > $1.updatedAt }
    }

    func delete(id: UUID) throws {
        let url = fileURL(for: id)
        guard fileManager.fileExists(atPath: url.path) else { return }
        do {
            try fileManager.removeItem(at: url)
        } catch {
            throw TrollyError.storageFailed(
                "Failed to delete script: \(error.localizedDescription)"
            )
        }
    }

    // MARK: - Private

    private func fileURL(for id: UUID) -> URL {
        baseDirectory.appendingPathComponent("\(id.uuidString).json")
    }

    private func ensureDirectoryExists() throws {
        guard !fileManager.fileExists(atPath: baseDirectory.path) else { return }
        do {
            try fileManager.createDirectory(
                at: baseDirectory,
                withIntermediateDirectories: true
            )
        } catch {
            throw TrollyError.storageFailed(
                "Failed to create scripts directory: \(error.localizedDescription)"
            )
        }
    }
}
