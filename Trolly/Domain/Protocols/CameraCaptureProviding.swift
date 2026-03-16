import Foundation
import CoreMedia
import AVFoundation

protocol CameraCaptureProviding: Sendable {
    func availableCameras() -> [AVCaptureDevice]
    func startCapture(
        sampleHandler: @Sendable @escaping (CMSampleBuffer) -> Void
    ) async throws
    func stopCapture() async throws
}
