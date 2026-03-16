import Foundation

final class TranscriptStorageService: @unchecked Sendable {

    private let fileManager: FileManager
    private let queue = DispatchQueue(label: "com.trolly.transcript-storage")
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()
    private let decoder = JSONDecoder()

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func save(transcript: Transcript, for recording: RecordingMetadata) async throws {
        let url = transcriptURL(for: recording)
        let data = try encoder.encode(transcript)
        let success = queue.sync {
            fileManager.createFile(atPath: url.path, contents: data)
        }
        guard success else {
            throw TrollyError.storageFailed(
                "Failed to write transcript to \(url.path)"
            )
        }
    }

    func load(for recording: RecordingMetadata) async throws -> Transcript? {
        let url = transcriptURL(for: recording)
        guard fileManager.fileExists(atPath: url.path) else {
            return nil
        }
        let data = try Data(contentsOf: url)
        return try decoder.decode(Transcript.self, from: data)
    }

    func exists(for recording: RecordingMetadata) -> Bool {
        let url = transcriptURL(for: recording)
        return fileManager.fileExists(atPath: url.path)
    }

    func delete(for recording: RecordingMetadata) throws {
        let url = transcriptURL(for: recording)
        guard fileManager.fileExists(atPath: url.path) else { return }
        do {
            try fileManager.removeItem(at: url)
        } catch {
            throw TrollyError.storageFailed(
                "Failed to delete transcript: \(error.localizedDescription)"
            )
        }
    }

    // MARK: - Private

    private func transcriptURL(for recording: RecordingMetadata) -> URL {
        recording.fileURL
            .deletingPathExtension()
            .appendingPathExtension("transcript")
            .appendingPathExtension("json")
    }
}
