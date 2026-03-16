import Foundation

protocol RecordingRepository: Sendable {
    func save(metadata: RecordingMetadata) async throws
    func fetchAll() async throws -> [RecordingMetadata]
    func delete(id: UUID) async throws
    func outputURL(for configuration: RecordingConfiguration) throws -> URL
}
