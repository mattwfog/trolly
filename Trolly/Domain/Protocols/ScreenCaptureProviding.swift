import Foundation
import CoreMedia
import ScreenCaptureKit

protocol ScreenCaptureProviding: Sendable {
    func availableDisplays() async throws -> [DisplayInfo]
    func availableWindows() async throws -> [WindowInfo]
    func startCapture(
        source: CaptureSource,
        configuration: RecordingConfiguration,
        sampleHandler: @Sendable @escaping (CMSampleBuffer, SCStreamOutputType) -> Void
    ) async throws
    func switchSource(
        to source: CaptureSource,
        configuration: RecordingConfiguration
    ) async throws
    func stopCapture() async throws
}
