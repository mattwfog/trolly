import Testing
import Foundation
@testable import Trolly

@Suite("TranscriptStorageService")
struct TranscriptStorageServiceTests {

    private let fileManager = FileManager.default

    private func makeTempDirectory() throws -> URL {
        let tempDir = fileManager.temporaryDirectory
            .appendingPathComponent("trolly-transcript-tests-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        return tempDir
    }

    private func makeRecording(in directory: URL, filename: String = "test") -> RecordingMetadata {
        RecordingMetadata(
            id: UUID(),
            createdAt: Date(),
            duration: 10.0,
            fileURL: directory.appendingPathComponent("\(filename).mp4"),
            fileSize: 1024,
            sourceName: "Test Display",
            hasWebcam: false,
            hasAudio: true
        )
    }

    private func makeTranscript() -> Transcript {
        Transcript(
            text: "Hello world. How are you?",
            segments: [
                TranscriptSegment(start: 0.0, end: 1.5, text: "Hello world."),
                TranscriptSegment(start: 1.5, end: 3.0, text: "How are you?"),
            ],
            language: "en",
            duration: 3.0
        )
    }

    private func cleanup(_ directory: URL) {
        try? fileManager.removeItem(at: directory)
    }

    // MARK: - save and load

    @Test("save and load round-trips transcript correctly")
    func testSaveAndLoad() async throws {
        let tempDir = try makeTempDirectory()
        defer { cleanup(tempDir) }

        let service = TranscriptStorageService(fileManager: fileManager)
        let recording = makeRecording(in: tempDir)
        let transcript = makeTranscript()

        try await service.save(transcript: transcript, for: recording)
        let loaded = try await service.load(for: recording)

        #expect(loaded != nil)
        #expect(loaded?.text == transcript.text)
        #expect(loaded?.segments.count == 2)
        #expect(loaded?.language == "en")
        #expect(loaded?.duration == 3.0)
    }

    @Test("load returns nil when no transcript exists")
    func testLoadReturnsNilWhenMissing() async throws {
        let tempDir = try makeTempDirectory()
        defer { cleanup(tempDir) }

        let service = TranscriptStorageService(fileManager: fileManager)
        let recording = makeRecording(in: tempDir)

        let loaded = try await service.load(for: recording)

        #expect(loaded == nil)
    }

    // MARK: - exists

    @Test("exists returns true after save")
    func testExistsAfterSave() async throws {
        let tempDir = try makeTempDirectory()
        defer { cleanup(tempDir) }

        let service = TranscriptStorageService(fileManager: fileManager)
        let recording = makeRecording(in: tempDir)
        let transcript = makeTranscript()

        #expect(!service.exists(for: recording))

        try await service.save(transcript: transcript, for: recording)

        #expect(service.exists(for: recording))
    }

    @Test("exists returns false when no transcript exists")
    func testExistsReturnsFalseWhenMissing() {
        let tempDir = fileManager.temporaryDirectory
            .appendingPathComponent("trolly-noexist-\(UUID().uuidString)", isDirectory: true)
        let service = TranscriptStorageService(fileManager: fileManager)
        let recording = makeRecording(in: tempDir)

        #expect(!service.exists(for: recording))
    }

    // MARK: - delete

    @Test("delete removes transcript file")
    func testDelete() async throws {
        let tempDir = try makeTempDirectory()
        defer { cleanup(tempDir) }

        let service = TranscriptStorageService(fileManager: fileManager)
        let recording = makeRecording(in: tempDir)
        let transcript = makeTranscript()

        try await service.save(transcript: transcript, for: recording)
        #expect(service.exists(for: recording))

        try service.delete(for: recording)
        #expect(!service.exists(for: recording))
    }

    @Test("delete does not throw when file does not exist")
    func testDeleteNonExistent() throws {
        let tempDir = fileManager.temporaryDirectory
            .appendingPathComponent("trolly-noexist-\(UUID().uuidString)", isDirectory: true)
        let service = TranscriptStorageService(fileManager: fileManager)
        let recording = makeRecording(in: tempDir)

        try service.delete(for: recording)
    }

    // MARK: - file naming

    @Test("transcript file is named .transcript.json")
    func testTranscriptFileNaming() async throws {
        let tempDir = try makeTempDirectory()
        defer { cleanup(tempDir) }

        let service = TranscriptStorageService(fileManager: fileManager)
        let recording = makeRecording(in: tempDir, filename: "2026-03-11_21-04-38")
        let transcript = makeTranscript()

        try await service.save(transcript: transcript, for: recording)

        let expectedPath = tempDir
            .appendingPathComponent("2026-03-11_21-04-38.transcript.json")
        #expect(fileManager.fileExists(atPath: expectedPath.path))
    }

    // MARK: - isolation from RecordingStorageRepository

    @Test("transcript files are not loaded by RecordingStorageRepository.fetchAll")
    func testTranscriptFilesExcludedFromRecordingFetch() async throws {
        let tempDir = try makeTempDirectory()
        defer { cleanup(tempDir) }

        let recordingRepo = RecordingStorageRepository(
            baseDirectory: tempDir,
            fileManager: fileManager
        )
        let transcriptService = TranscriptStorageService(fileManager: fileManager)

        // Save a recording
        let fileURL = tempDir.appendingPathComponent("test.mp4")
        fileManager.createFile(atPath: fileURL.path, contents: Data("video".utf8))
        let recording = RecordingMetadata(
            id: UUID(),
            createdAt: Date(),
            duration: 10.0,
            fileURL: fileURL,
            fileSize: 1024,
            sourceName: "Test Display",
            hasWebcam: false,
            hasAudio: true
        )
        try await recordingRepo.save(metadata: recording)

        // Save a transcript alongside it
        try await transcriptService.save(transcript: makeTranscript(), for: recording)

        // fetchAll should only return 1 recording, not crash on the transcript file
        let results = try await recordingRepo.fetchAll()
        #expect(results.count == 1)
        #expect(results[0].id == recording.id)
    }
}
