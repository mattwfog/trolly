import Testing
import Foundation
@testable import Trolly

@Suite("ScriptStorageService")
struct ScriptStorageServiceTests {

    private let fileManager = FileManager.default

    private func makeTempDirectory() throws -> URL {
        let tempDir = fileManager.temporaryDirectory
            .appendingPathComponent("trolly-script-tests-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        return tempDir
    }

    private func cleanup(_ directory: URL) {
        try? fileManager.removeItem(at: directory)
    }

    // MARK: - save and load

    @Test("save and load round-trips script correctly")
    func testSaveAndLoad() async throws {
        let tempDir = try makeTempDirectory()
        defer { cleanup(tempDir) }

        let service = ScriptStorageService(baseDirectory: tempDir, fileManager: fileManager)
        let script = Script.create(title: "Test Script", content: "Hello world")

        try await service.save(script: script)
        let loaded = try await service.load(id: script.id)

        #expect(loaded != nil)
        #expect(loaded?.id == script.id)
        #expect(loaded?.title == "Test Script")
        #expect(loaded?.content == "Hello world")
    }

    @Test("load returns nil for nonexistent script")
    func testLoadNonExistent() async throws {
        let tempDir = try makeTempDirectory()
        defer { cleanup(tempDir) }

        let service = ScriptStorageService(baseDirectory: tempDir, fileManager: fileManager)
        let loaded = try await service.load(id: UUID())

        #expect(loaded == nil)
    }

    // MARK: - fetchAll

    @Test("fetchAll returns scripts sorted by updatedAt descending")
    func testFetchAllSorted() async throws {
        let tempDir = try makeTempDirectory()
        defer { cleanup(tempDir) }

        let service = ScriptStorageService(baseDirectory: tempDir, fileManager: fileManager)

        let older = Script(
            id: UUID(), title: "Older", content: "A",
            createdAt: Date(timeIntervalSince1970: 1000),
            updatedAt: Date(timeIntervalSince1970: 1000)
        )
        let newer = Script(
            id: UUID(), title: "Newer", content: "B",
            createdAt: Date(timeIntervalSince1970: 2000),
            updatedAt: Date(timeIntervalSince1970: 2000)
        )

        try await service.save(script: older)
        try await service.save(script: newer)

        let results = try await service.fetchAll()

        #expect(results.count == 2)
        #expect(results[0].title == "Newer")
        #expect(results[1].title == "Older")
    }

    @Test("fetchAll returns empty when no scripts exist")
    func testFetchAllEmpty() async throws {
        let tempDir = try makeTempDirectory()
        defer { cleanup(tempDir) }

        let service = ScriptStorageService(baseDirectory: tempDir, fileManager: fileManager)
        let results = try await service.fetchAll()

        #expect(results.isEmpty)
    }

    @Test("fetchAll returns empty when directory does not exist")
    func testFetchAllNoDirectory() async throws {
        let tempDir = fileManager.temporaryDirectory
            .appendingPathComponent("trolly-noexist-\(UUID().uuidString)", isDirectory: true)

        let service = ScriptStorageService(baseDirectory: tempDir, fileManager: fileManager)
        let results = try await service.fetchAll()

        #expect(results.isEmpty)
    }

    // MARK: - delete

    @Test("delete removes script file")
    func testDelete() async throws {
        let tempDir = try makeTempDirectory()
        defer { cleanup(tempDir) }

        let service = ScriptStorageService(baseDirectory: tempDir, fileManager: fileManager)
        let script = Script.create(title: "Delete Me", content: "Goodbye")

        try await service.save(script: script)
        let loaded = try await service.load(id: script.id)
        #expect(loaded != nil)

        try service.delete(id: script.id)
        let afterDelete = try await service.load(id: script.id)
        #expect(afterDelete == nil)
    }

    @Test("delete does not throw for nonexistent script")
    func testDeleteNonExistent() throws {
        let tempDir = fileManager.temporaryDirectory
            .appendingPathComponent("trolly-noexist-\(UUID().uuidString)", isDirectory: true)

        let service = ScriptStorageService(baseDirectory: tempDir, fileManager: fileManager)
        try service.delete(id: UUID())
    }

    // MARK: - save creates directory

    @Test("save creates scripts directory if it does not exist")
    func testSaveCreatesDirectory() async throws {
        let tempDir = fileManager.temporaryDirectory
            .appendingPathComponent("trolly-script-create-\(UUID().uuidString)", isDirectory: true)
        defer { cleanup(tempDir) }

        #expect(!fileManager.fileExists(atPath: tempDir.path))

        let service = ScriptStorageService(baseDirectory: tempDir, fileManager: fileManager)
        let script = Script.create(title: "First", content: "Content")
        try await service.save(script: script)

        #expect(fileManager.fileExists(atPath: tempDir.path))
    }

    // MARK: - update

    @Test("saving updated script overwrites previous version")
    func testUpdate() async throws {
        let tempDir = try makeTempDirectory()
        defer { cleanup(tempDir) }

        let service = ScriptStorageService(baseDirectory: tempDir, fileManager: fileManager)
        let script = Script.create(title: "V1", content: "Old content")
        try await service.save(script: script)

        let updated = script.withTitle("V2").withContent("New content")
        try await service.save(script: updated)

        let loaded = try await service.load(id: script.id)
        #expect(loaded?.title == "V2")
        #expect(loaded?.content == "New content")

        let all = try await service.fetchAll()
        #expect(all.count == 1)
    }
}
