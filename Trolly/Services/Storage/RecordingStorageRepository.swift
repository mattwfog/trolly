import Foundation

final class RecordingStorageRepository: RecordingRepository, @unchecked Sendable {

    private let baseDirectory: URL
    private let fileManager: FileManager
    private let queue = DispatchQueue(label: "com.trolly.storage")
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()
    private let decoder = JSONDecoder()

    init(fileManager: FileManager = .default) {
        self.baseDirectory = RecordingConfiguration.defaultOutputDirectory
        self.fileManager = fileManager
    }

    init(baseDirectory: URL, fileManager: FileManager = .default) {
        self.baseDirectory = baseDirectory
        self.fileManager = fileManager
    }

    func outputURL(for configuration: RecordingConfiguration) throws -> URL {
        let directory = configuration.outputDirectory
        try ensureDirectoryExists(at: directory)
        try validateDirectoryIsWritable(at: directory)

        let filename = configuration.outputFilename ?? generateTimestampedFilename()
        return directory
            .appendingPathComponent(filename)
            .appendingPathExtension("mp4")
    }

    func save(metadata: RecordingMetadata) async throws {
        let jsonURL = metadataURL(for: metadata.fileURL)
        let data = try encoder.encode(metadata)
        let success = queue.sync {
            fileManager.createFile(atPath: jsonURL.path, contents: data)
        }
        guard success else {
            throw TrollyError.storageFailed(
                "Failed to write metadata to \(jsonURL.path)"
            )
        }
    }

    func fetchAll() async throws -> [RecordingMetadata] {
        guard fileManager.fileExists(atPath: baseDirectory.path) else {
            return []
        }
        let contents = try queue.sync {
            try fileManager.contentsOfDirectory(
                at: baseDirectory,
                includingPropertiesForKeys: nil
            )
        }
        let jsonFiles = contents.filter {
            $0.pathExtension == "json"
                && !$0.lastPathComponent.hasSuffix(".transcript.json")
        }
        let decoded = try jsonFiles.compactMap { url -> RecordingMetadata? in
            let data = try Data(contentsOf: url)
            return try decoder.decode(RecordingMetadata.self, from: data)
        }
        return decoded.sorted { $0.createdAt > $1.createdAt }
    }

    func delete(id: UUID) async throws {
        let allMetadata = try await fetchAll()
        guard let metadata = allMetadata.first(where: { $0.id == id }) else {
            throw TrollyError.recordingNotFound(id)
        }
        let jsonURL = metadataURL(for: metadata.fileURL)
        try removeFileIfExists(at: jsonURL)
        try removeFileIfExists(at: metadata.fileURL)
    }

    // MARK: - Private helpers

    private func generateTimestampedFilename() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter.string(from: Date())
    }

    private func metadataURL(for videoURL: URL) -> URL {
        videoURL
            .deletingPathExtension()
            .appendingPathExtension("json")
    }

    private func ensureDirectoryExists(at url: URL) throws {
        guard !fileManager.fileExists(atPath: url.path) else { return }
        do {
            try fileManager.createDirectory(
                at: url, withIntermediateDirectories: true
            )
        } catch {
            throw TrollyError.storageFailed(
                "Failed to create directory: \(error.localizedDescription)"
            )
        }
    }

    private func validateDirectoryIsWritable(at url: URL) throws {
        guard fileManager.isWritableFile(atPath: url.path) else {
            throw TrollyError.outputDirectoryNotWritable(url.path)
        }
    }

    private func removeFileIfExists(at url: URL) throws {
        guard fileManager.fileExists(atPath: url.path) else { return }
        do {
            try fileManager.removeItem(at: url)
        } catch {
            throw TrollyError.storageFailed(
                "Failed to delete \(url.lastPathComponent): \(error.localizedDescription)"
            )
        }
    }
}
