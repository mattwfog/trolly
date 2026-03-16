import Foundation
import CoreMedia
import AVFoundation
@testable import Trolly

final class MockCameraCaptureProvider: CameraCaptureProviding, @unchecked Sendable {
    var cameras: [AVCaptureDevice] = []
    var startCaptureError: Error?
    var stopCaptureError: Error?

    private(set) var startCaptureCallCount = 0
    private(set) var stopCaptureCallCount = 0

    func availableCameras() -> [AVCaptureDevice] {
        cameras
    }

    func startCapture(
        sampleHandler: @Sendable @escaping (CMSampleBuffer) -> Void
    ) async throws {
        startCaptureCallCount += 1
        if let error = startCaptureError {
            throw error
        }
    }

    func stopCapture() async throws {
        stopCaptureCallCount += 1
        if let error = stopCaptureError {
            throw error
        }
    }
}
