import Foundation
import CoreMedia
import AVFoundation

protocol AudioCaptureProviding: Sendable {
    func availableMicrophones() -> [AVCaptureDevice]
    func startCapture(
        sampleHandler: @Sendable @escaping (CMSampleBuffer) -> Void
    ) async throws
    func stopCapture() async throws
}
