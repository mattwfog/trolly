import Foundation
import CoreMedia
import AVFoundation

final class AudioCaptureService: NSObject, AudioCaptureProviding,
    AVCaptureAudioDataOutputSampleBufferDelegate, @unchecked Sendable {

    private let session = AVCaptureSession()
    private let outputQueue = DispatchQueue(label: "com.trolly.audio-capture", qos: .userInitiated)
    private var sampleHandler: (@Sendable (CMSampleBuffer) -> Void)?

    // MARK: - AudioCaptureProviding

    func availableMicrophones() -> [AVCaptureDevice] {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInMicrophone, .externalUnknown],
            mediaType: .audio,
            position: .unspecified
        )
        return discoverySession.devices
    }

    func startCapture(
        sampleHandler: @Sendable @escaping (CMSampleBuffer) -> Void
    ) async throws {
        guard let microphone = AVCaptureDevice.default(for: .audio) else {
            throw TrollyError.microphoneUnavailable
        }

        self.sampleHandler = sampleHandler

        let input = try AVCaptureDeviceInput(device: microphone)
        let output = AVCaptureAudioDataOutput()
        output.setSampleBufferDelegate(self, queue: outputQueue)

        session.beginConfiguration()

        guard session.canAddInput(input) else {
            session.commitConfiguration()
            throw TrollyError.microphoneUnavailable
        }
        session.addInput(input)

        guard session.canAddOutput(output) else {
            session.commitConfiguration()
            throw TrollyError.microphoneUnavailable
        }
        session.addOutput(output)

        session.commitConfiguration()
        session.startRunning()
    }

    func stopCapture() async throws {
        session.stopRunning()
        sampleHandler = nil
    }

    // MARK: - AVCaptureAudioDataOutputSampleBufferDelegate

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        sampleHandler?(sampleBuffer)
    }
}
