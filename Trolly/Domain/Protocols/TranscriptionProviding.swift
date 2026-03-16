import Foundation

protocol TranscriptionProviding: Sendable {
    func transcribe(filePath: URL) async throws -> Transcript
}
