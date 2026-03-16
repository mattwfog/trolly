import Foundation
import CoreGraphics

struct RecordingConfiguration: Equatable, Sendable {
    let captureSource: CaptureSource?
    let captureFrameRate: Int
    let captureResolution: CGSize?
    let webcamEnabled: Bool
    let webcamPosition: WebcamPosition
    let webcamSize: WebcamSize
    let microphoneEnabled: Bool
    let outputDirectory: URL
    let outputFilename: String?

    static let defaultFrameRate = 30
    static let minFrameRate = 1
    static let maxFrameRate = 60

    static let `default` = RecordingConfiguration(
        captureSource: nil,
        captureFrameRate: defaultFrameRate,
        captureResolution: nil,
        webcamEnabled: true,
        webcamPosition: .bottomLeft,
        webcamSize: .medium,
        microphoneEnabled: true,
        outputDirectory: RecordingConfiguration.defaultOutputDirectory,
        outputFilename: nil
    )

    func withCaptureSource(_ source: CaptureSource) -> RecordingConfiguration {
        RecordingConfiguration(
            captureSource: source,
            captureFrameRate: captureFrameRate,
            captureResolution: captureResolution,
            webcamEnabled: webcamEnabled,
            webcamPosition: webcamPosition,
            webcamSize: webcamSize,
            microphoneEnabled: microphoneEnabled,
            outputDirectory: outputDirectory,
            outputFilename: outputFilename
        )
    }

    func withWebcam(enabled: Bool) -> RecordingConfiguration {
        RecordingConfiguration(
            captureSource: captureSource,
            captureFrameRate: captureFrameRate,
            captureResolution: captureResolution,
            webcamEnabled: enabled,
            webcamPosition: webcamPosition,
            webcamSize: webcamSize,
            microphoneEnabled: microphoneEnabled,
            outputDirectory: outputDirectory,
            outputFilename: outputFilename
        )
    }

    func withMicrophone(enabled: Bool) -> RecordingConfiguration {
        RecordingConfiguration(
            captureSource: captureSource,
            captureFrameRate: captureFrameRate,
            captureResolution: captureResolution,
            webcamEnabled: webcamEnabled,
            webcamPosition: webcamPosition,
            webcamSize: webcamSize,
            microphoneEnabled: enabled,
            outputDirectory: outputDirectory,
            outputFilename: outputFilename
        )
    }

    func withWebcamPosition(_ position: WebcamPosition) -> RecordingConfiguration {
        RecordingConfiguration(
            captureSource: captureSource,
            captureFrameRate: captureFrameRate,
            captureResolution: captureResolution,
            webcamEnabled: webcamEnabled,
            webcamPosition: position,
            webcamSize: webcamSize,
            microphoneEnabled: microphoneEnabled,
            outputDirectory: outputDirectory,
            outputFilename: outputFilename
        )
    }

    func withWebcamSize(_ size: WebcamSize) -> RecordingConfiguration {
        RecordingConfiguration(
            captureSource: captureSource,
            captureFrameRate: captureFrameRate,
            captureResolution: captureResolution,
            webcamEnabled: webcamEnabled,
            webcamPosition: webcamPosition,
            webcamSize: size,
            microphoneEnabled: microphoneEnabled,
            outputDirectory: outputDirectory,
            outputFilename: outputFilename
        )
    }

    var isValid: Bool {
        captureSource != nil
            && captureFrameRate >= Self.minFrameRate
            && captureFrameRate <= Self.maxFrameRate
    }

    static var defaultOutputDirectory: URL {
        FileManager.default.urls(for: .moviesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Trolly", isDirectory: true)
    }
}

enum WebcamPosition: String, Codable, CaseIterable, Sendable {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
}

enum WebcamSize: String, Codable, CaseIterable, Sendable {
    case small
    case medium
    case large

    var relativeDiameter: CGFloat {
        switch self {
        case .small: return 0.15
        case .medium: return 0.22
        case .large: return 0.30
        }
    }
}
