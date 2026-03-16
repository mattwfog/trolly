import Foundation

struct RecordingMetadata: Equatable, Hashable, Sendable, Codable, Identifiable {
    let id: UUID
    let createdAt: Date
    let duration: TimeInterval
    let fileURL: URL
    let fileSize: Int64
    let sourceName: String
    let hasWebcam: Bool
    let hasAudio: Bool

    static func create(
        duration: TimeInterval,
        fileURL: URL,
        fileSize: Int64,
        sourceName: String,
        hasWebcam: Bool,
        hasAudio: Bool
    ) -> RecordingMetadata {
        RecordingMetadata(
            id: UUID(),
            createdAt: Date(),
            duration: duration,
            fileURL: fileURL,
            fileSize: fileSize,
            sourceName: sourceName,
            hasWebcam: hasWebcam,
            hasAudio: hasAudio
        )
    }
}
