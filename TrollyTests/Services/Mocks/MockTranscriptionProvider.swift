import Foundation
@testable import Trolly

final class MockTranscriptionProvider: TranscriptionProviding, @unchecked Sendable {
    var transcribeResult: Result<Transcript, Error> = .success(
        Transcript(
            text: "Hello world",
            segments: [
                TranscriptSegment(start: 0.0, end: 2.5, text: "Hello world")
            ],
            language: "en",
            duration: 2.5
        )
    )

    private(set) var transcribeCalls: [URL] = []

    func transcribe(filePath: URL) async throws -> Transcript {
        transcribeCalls.append(filePath)
        return try transcribeResult.get()
    }
}
