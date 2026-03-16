import Foundation
@testable import Trolly

final class MockRecordingRepository: RecordingRepository, @unchecked Sendable {
    var saveError: Error?
    var fetchAllResult: Result<[RecordingMetadata], Error> = .success([])
    var deleteError: Error?
    var outputURLResult: Result<URL, Error> = .success(
        URL(fileURLWithPath: "/tmp/trolly-test/recording.mp4")
    )

    private(set) var savedMetadata: [RecordingMetadata] = []
    private(set) var deletedIds: [UUID] = []
    private(set) var fetchAllCallCount = 0
    private(set) var outputURLCallCount = 0

    func save(metadata: RecordingMetadata) async throws {
        if let error = saveError {
            throw error
        }
        savedMetadata.append(metadata)
    }

    func fetchAll() async throws -> [RecordingMetadata] {
        fetchAllCallCount += 1
        return try fetchAllResult.get()
    }

    func delete(id: UUID) async throws {
        if let error = deleteError {
            throw error
        }
        deletedIds.append(id)
    }

    func outputURL(for configuration: RecordingConfiguration) throws -> URL {
        outputURLCallCount += 1
        return try outputURLResult.get()
    }
}
