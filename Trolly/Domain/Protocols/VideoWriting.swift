import Foundation
import CoreMedia
import CoreGraphics

protocol VideoWriting: Sendable {
    func setup(
        outputURL: URL,
        videoSize: CGSize,
        hasWebcam: Bool,
        webcamPosition: WebcamPosition,
        webcamSize: WebcamSize,
        hasAudio: Bool
    ) throws
    func appendVideoSample(_ sampleBuffer: CMSampleBuffer) throws
    func appendWebcamSample(_ sampleBuffer: CMSampleBuffer) throws
    func appendAudioSample(_ sampleBuffer: CMSampleBuffer) throws
    func finishWriting() async throws -> URL
}
