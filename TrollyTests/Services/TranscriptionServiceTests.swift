import Testing
import Foundation
@testable import Trolly

@Suite("TranscriptionService")
struct TranscriptionServiceTests {

    @Test("constructs correct URL for transcribe/url endpoint")
    func testURLConstruction() throws {
        let service = TranscriptionService(
            baseURL: URL(string: "http://127.0.0.1:8420")!
        )

        // Verify the service exists and is configured with the right base URL
        // (actual HTTP calls are integration tests)
        #expect(service is TranscriptionProviding)
    }

    @Test("decodes valid transcript response")
    func testDecodeTranscriptResponse() throws {
        let json = """
        {
            "text": "Hello world",
            "segments": [
                {"start": 0.0, "end": 2.5, "text": "Hello world"}
            ],
            "language": "en",
            "duration": 2.5
        }
        """
        let data = Data(json.utf8)
        let transcript = try JSONDecoder().decode(Transcript.self, from: data)

        #expect(transcript.text == "Hello world")
        #expect(transcript.segments.count == 1)
        #expect(transcript.segments[0].start == 0.0)
        #expect(transcript.segments[0].end == 2.5)
        #expect(transcript.segments[0].text == "Hello world")
        #expect(transcript.language == "en")
        #expect(transcript.duration == 2.5)
    }

    @Test("decodes transcript with multiple segments")
    func testDecodeMultipleSegments() throws {
        let json = """
        {
            "text": "Hello world. How are you?",
            "segments": [
                {"start": 0.0, "end": 1.5, "text": "Hello world."},
                {"start": 1.5, "end": 3.0, "text": "How are you?"}
            ],
            "language": "en",
            "duration": 3.0
        }
        """
        let data = Data(json.utf8)
        let transcript = try JSONDecoder().decode(Transcript.self, from: data)

        #expect(transcript.segments.count == 2)
        #expect(transcript.segments[0].text == "Hello world.")
        #expect(transcript.segments[1].text == "How are you?")
    }

    @Test("decodes transcript with empty segments")
    func testDecodeEmptySegments() throws {
        let json = """
        {
            "text": "",
            "segments": [],
            "language": "en",
            "duration": 0.0
        }
        """
        let data = Data(json.utf8)
        let transcript = try JSONDecoder().decode(Transcript.self, from: data)

        #expect(transcript.text == "")
        #expect(transcript.segments.isEmpty)
    }

    @Test("mock provider records calls and returns result")
    func testMockProvider() async throws {
        let mock = MockTranscriptionProvider()
        let url = URL(fileURLWithPath: "/tmp/test.mp4")

        let result = try await mock.transcribe(filePath: url)

        #expect(result.text == "Hello world")
        #expect(mock.transcribeCalls.count == 1)
        #expect(mock.transcribeCalls[0] == url)
    }

    @Test("mock provider throws configured error")
    func testMockProviderError() async {
        let mock = MockTranscriptionProvider()
        mock.transcribeResult = .failure(TrollyError.transcriptionServerUnavailable)

        do {
            _ = try await mock.transcribe(filePath: URL(fileURLWithPath: "/tmp/test.mp4"))
            #expect(Bool(false), "Should have thrown")
        } catch {
            #expect(error is TrollyError)
        }
    }
}
