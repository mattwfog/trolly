import Foundation

struct Transcript: Codable, Equatable, Sendable {
    let text: String
    let segments: [TranscriptSegment]
    let language: String
    let duration: TimeInterval
}

struct TranscriptSegment: Codable, Equatable, Sendable {
    let start: TimeInterval
    let end: TimeInterval
    let text: String
}
