import Foundation
import CoreMedia
import CoreGraphics
@testable import Trolly

final class MockVideoWriter: VideoWriting, @unchecked Sendable {
    var setupError: Error?
    var appendVideoError: Error?
    var appendWebcamError: Error?
    var appendAudioError: Error?
    var finishWritingError: Error?
    var finishWritingURL: URL = URL(fileURLWithPath: "/tmp/test-output.mp4")

    private(set) var setupCallCount = 0
    private(set) var appendVideoCallCount = 0
    private(set) var appendWebcamCallCount = 0
    private(set) var appendAudioCallCount = 0
    private(set) var finishWritingCallCount = 0
    private(set) var lastOutputURL: URL?
    private(set) var lastVideoSize: CGSize?
    private(set) var lastHasAudio: Bool?

    func setup(
        outputURL: URL,
        videoSize: CGSize,
        hasWebcam: Bool,
        webcamPosition: WebcamPosition,
        webcamSize: WebcamSize,
        hasAudio: Bool
    ) throws {
        setupCallCount += 1
        lastOutputURL = outputURL
        lastVideoSize = videoSize
        lastHasAudio = hasAudio
        if let error = setupError {
            throw error
        }
    }

    func appendVideoSample(_ sampleBuffer: CMSampleBuffer) throws {
        appendVideoCallCount += 1
        if let error = appendVideoError {
            throw error
        }
    }

    func appendWebcamSample(_ sampleBuffer: CMSampleBuffer) throws {
        appendWebcamCallCount += 1
        if let error = appendWebcamError {
            throw error
        }
    }

    func appendAudioSample(_ sampleBuffer: CMSampleBuffer) throws {
        appendAudioCallCount += 1
        if let error = appendAudioError {
            throw error
        }
    }

    func finishWriting() async throws -> URL {
        finishWritingCallCount += 1
        if let error = finishWritingError {
            throw error
        }
        return finishWritingURL
    }
}
