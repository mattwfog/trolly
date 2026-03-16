import Testing
import Foundation
@testable import Trolly

@Suite("RecordingStorageRepository")
struct RecordingStorageRepositoryTests {

    private let fileManager = FileManager.default

    private func makeTempDirectory() throws -> URL {
        let tempDir = fileManager.temporaryDirectory
            .appendingPathComponent("trolly-tests-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        return tempDir
    }

    private func makeConfig(outputDirectory: URL, outputFilename: String? = nil) -> RecordingConfiguration {
        RecordingConfiguration(
            captureSource: nil,
            captureFrameRate: 30,
            captureResolution: nil,
            webcamEnabled: false,
            webcamPosition: .bottomLeft,
            webcamSize: .medium,
            microphoneEnabled: false,
            outputDirectory: outputDirectory,
            outputFilename: outputFilename
        )
    }

    private func makeMetadata(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        fileURL: URL = URL(fileURLWithPath: "/tmp/test.mp4")
    ) -> RecordingMetadata {
        RecordingMetadata(
            id: id,
            createdAt: createdAt,
            duration: 10.0,
            fileURL: fileURL,
            fileSize: 1024,
            sourceName: "Test Display",
            hasWebcam: false,
            hasAudio: true
        )
    }

    private func cleanup(_ directory: URL) {
        try? fileManager.removeItem(at: directory)
    }

    // MARK: - outputURL tests

    @Test("outputURL creates directory if it does not exist")
    func testOutputURL_createsDirectoryIfNeeded() throws {
        let tempDir = fileManager.temporaryDirectory
            .appendingPathComponent("trolly-tests-\(UUID().uuidString)", isDirectory: true)
        defer { cleanup(tempDir) }

        let config = makeConfig(outputDirectory: tempDir)
        let repo = RecordingStorageRepository(fileManager: fileManager)

        let url = try repo.outputURL(for: config)

        #expect(fileManager.fileExists(atPath: tempDir.path))
        #expect(url.pathExtension == "mp4")
    }

    @Test("outputURL generates timestamped filename")
    func testOutputURL_generatesTimestampedFilename() throws {
        let tempDir = try makeTempDirectory()
        defer { cleanup(tempDir) }

        let config = makeConfig(outputDirectory: tempDir)
        let repo = RecordingStorageRepository(fileManager: fileManager)

        let url = try repo.outputURL(for: config)

        let filename = url.deletingPathExtension().lastPathComponent
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let parsed = dateFormatter.date(from: filename)
        #expect(parsed != nil)
        #expect(url.pathExtension == "mp4")
    }

    @Test("outputURL uses custom filename when provided")
    func testOutputURL_usesCustomFilenameWhenProvided() throws {
        let tempDir = try makeTempDirectory()
        defer { cleanup(tempDir) }

        let config = makeConfig(outputDirectory: tempDir, outputFilename: "my-recording")
        let repo = RecordingStorageRepository(fileManager: fileManager)

        let url = try repo.outputURL(for: config)

        #expect(url.deletingPathExtension().lastPathComponent == "my-recording")
        #expect(url.pathExtension == "mp4")
    }

    // MARK: - save and fetchAll tests

    @Test("save and fetchAll round-trips metadata correctly")
    func testSaveAndFetchAll_roundTripsMetadata() async throws {
        let tempDir = try makeTempDirectory()
        defer { cleanup(tempDir) }

        let repo = RecordingStorageRepository(
            baseDirectory: tempDir,
            fileManager: fileManager
        )
        let fileURL = tempDir.appendingPathComponent("test.mp4")
        fileManager.createFile(atPath: fileURL.path, contents: Data("video".utf8))

        let metadata = makeMetadata(fileURL: fileURL)
        try await repo.save(metadata: metadata)

        let results = try await repo.fetchAll()

        #expect(results.count == 1)
        #expect(results[0].id == metadata.id)
        #expect(results[0].duration == metadata.duration)
        #expect(results[0].fileSize == metadata.fileSize)
        #expect(results[0].sourceName == metadata.sourceName)
        #expect(results[0].hasWebcam == metadata.hasWebcam)
        #expect(results[0].hasAudio == metadata.hasAudio)
    }

    @Test("fetchAll returns results sorted by date descending")
    func testFetchAll_returnsSortedByDateDescending() async throws {
        let tempDir = try makeTempDirectory()
        defer { cleanup(tempDir) }

        let repo = RecordingStorageRepository(
            baseDirectory: tempDir,
            fileManager: fileManager
        )

        let oldest = makeMetadata(
            createdAt: Date(timeIntervalSince1970: 1000),
            fileURL: tempDir.appendingPathComponent("oldest.mp4")
        )
        let middle = makeMetadata(
            createdAt: Date(timeIntervalSince1970: 2000),
            fileURL: tempDir.appendingPathComponent("middle.mp4")
        )
        let newest = makeMetadata(
            createdAt: Date(timeIntervalSince1970: 3000),
            fileURL: tempDir.appendingPathComponent("newest.mp4")
        )

        for metadata in [middle, oldest, newest] {
            fileManager.createFile(
                atPath: metadata.fileURL.path, contents: Data("v".utf8)
            )
            try await repo.save(metadata: metadata)
        }

        let results = try await repo.fetchAll()

        #expect(results.count == 3)
        #expect(results[0].id == newest.id)
        #expect(results[1].id == middle.id)
        #expect(results[2].id == oldest.id)
    }

    @Test("fetchAll returns empty array when no recordings exist")
    func testFetchAll_returnsEmptyForNoRecordings() async throws {
        let tempDir = try makeTempDirectory()
        defer { cleanup(tempDir) }

        let repo = RecordingStorageRepository(
            baseDirectory: tempDir,
            fileManager: fileManager
        )

        let results = try await repo.fetchAll()

        #expect(results.isEmpty)
    }

    // MARK: - delete tests

    @Test("delete removes both JSON and MP4 files")
    func testDelete_removesBothFiles() async throws {
        let tempDir = try makeTempDirectory()
        defer { cleanup(tempDir) }

        let repo = RecordingStorageRepository(
            baseDirectory: tempDir,
            fileManager: fileManager
        )
        let fileURL = tempDir.appendingPathComponent("recording.mp4")
        fileManager.createFile(atPath: fileURL.path, contents: Data("video".utf8))

        let metadata = makeMetadata(fileURL: fileURL)
        try await repo.save(metadata: metadata)

        let jsonURL = fileURL.deletingPathExtension().appendingPathExtension("json")
        #expect(fileManager.fileExists(atPath: fileURL.path))
        #expect(fileManager.fileExists(atPath: jsonURL.path))

        try await repo.delete(id: metadata.id)

        #expect(!fileManager.fileExists(atPath: fileURL.path))
        #expect(!fileManager.fileExists(atPath: jsonURL.path))
    }
}
