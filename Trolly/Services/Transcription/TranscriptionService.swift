import Foundation

final class TranscriptionService: TranscriptionProviding, @unchecked Sendable {

    private let baseURL: URL
    private let session: URLSession

    init(
        baseURL: URL = URL(string: "http://127.0.0.1:8420")!,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.session = session
    }

    func transcribe(filePath: URL) async throws -> Transcript {
        let endpoint = baseURL.appendingPathComponent("transcribe/url")

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 300

        let body = TranscribeURLRequestBody(filePath: filePath.path)
        request.httpBody = try JSONEncoder().encode(body)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError where error.code == .cannotConnectToHost
            || error.code == .networkConnectionLost
            || error.code == .timedOut
        {
            throw TrollyError.transcriptionServerUnavailable
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TrollyError.transcriptionFailed("Invalid response from server")
        }

        guard httpResponse.statusCode == 200 else {
            let detail = parseErrorDetail(from: data)
            throw TrollyError.transcriptionFailed(detail)
        }

        do {
            return try JSONDecoder().decode(Transcript.self, from: data)
        } catch {
            throw TrollyError.transcriptionFailed(
                "Failed to decode response: \(error.localizedDescription)"
            )
        }
    }

    // MARK: - Private

    private func parseErrorDetail(from data: Data) -> String {
        struct ErrorResponse: Decodable {
            let detail: String
        }
        if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
            return errorResponse.detail
        }
        return "Server returned an error"
    }
}

private struct TranscribeURLRequestBody: Encodable {
    let filePath: String

    enum CodingKeys: String, CodingKey {
        case filePath = "file_path"
    }
}
