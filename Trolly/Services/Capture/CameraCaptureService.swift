import Foundation
import CoreMedia
import AVFoundation

final class CameraCaptureService: NSObject, CameraCaptureProviding,
    AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {

    private let session = AVCaptureSession()
    private let outputQueue = DispatchQueue(label: "com.trolly.camera-capture", qos: .userInitiated)
    private var sampleHandler: (@Sendable (CMSampleBuffer) -> Void)?

    // MARK: - CameraCaptureProviding

    func availableCameras() -> [AVCaptureDevice] {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .externalUnknown],
            mediaType: .video,
            position: .unspecified
        )
        return discoverySession.devices
    }

    func startCapture(
        sampleHandler: @Sendable @escaping (CMSampleBuffer) -> Void
    ) async throws {
        guard let camera = AVCaptureDevice.default(for: .video) else {
            throw TrollyError.cameraUnavailable
        }

        self.sampleHandler = sampleHandler

        let input = try AVCaptureDeviceInput(device: camera)
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: outputQueue)

        session.beginConfiguration()
        session.sessionPreset = .medium

        guard session.canAddInput(input) else {
            session.commitConfiguration()
            throw TrollyError.cameraUnavailable
        }
        session.addInput(input)

        guard session.canAddOutput(output) else {
            session.commitConfiguration()
            throw TrollyError.cameraUnavailable
        }
        session.addOutput(output)

        session.commitConfiguration()
        session.startRunning()
    }

    func stopCapture() async throws {
        session.stopRunning()
        sampleHandler = nil
    }

    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        sampleHandler?(sampleBuffer)
    }
}
