import AVFoundation
import CoreGraphics
import Observation

@Observable
@MainActor
final class PermissionManager {
    private(set) var screenCaptureGranted: Bool = false
    private(set) var cameraGranted: Bool = false
    private(set) var microphoneGranted: Bool = false

    private let screenCaptureChecker: @Sendable () -> Bool
    private let screenCaptureRequester: @Sendable () -> Bool
    private let avAuthorizationStatus: @Sendable (AVMediaType) -> AVAuthorizationStatus
    private let avRequestAccess: @Sendable (AVMediaType) async -> Bool

    init(
        screenCaptureChecker: @escaping @Sendable () -> Bool = { CGPreflightScreenCaptureAccess() },
        screenCaptureRequester: @escaping @Sendable () -> Bool = { CGRequestScreenCaptureAccess() },
        avAuthorizationStatus: @escaping @Sendable (AVMediaType) -> AVAuthorizationStatus = {
            AVCaptureDevice.authorizationStatus(for: $0)
        },
        avRequestAccess: @escaping @Sendable (AVMediaType) async -> Bool = {
            await AVCaptureDevice.requestAccess(for: $0)
        }
    ) {
        self.screenCaptureChecker = screenCaptureChecker
        self.screenCaptureRequester = screenCaptureRequester
        self.avAuthorizationStatus = avAuthorizationStatus
        self.avRequestAccess = avRequestAccess
    }

    func checkAllPermissions() async {
        checkScreenCapturePermission()
        checkCameraPermission()
        checkMicrophonePermission()
    }

    func requestScreenCapturePermission() async throws {
        let granted = screenCaptureRequester()
        screenCaptureGranted = granted
        if !granted {
            throw TrollyError.screenCapturePermissionDenied
        }
    }

    func requestCameraPermission() async -> Bool {
        let granted = await avRequestAccess(.video)
        cameraGranted = granted
        return granted
    }

    func requestMicrophonePermission() async -> Bool {
        let granted = await avRequestAccess(.audio)
        microphoneGranted = granted
        return granted
    }

    // MARK: - Private

    private func checkScreenCapturePermission() {
        screenCaptureGranted = screenCaptureChecker()
    }

    private func checkCameraPermission() {
        let status = avAuthorizationStatus(.video)
        cameraGranted = status == .authorized
    }

    private func checkMicrophonePermission() {
        let status = avAuthorizationStatus(.audio)
        microphoneGranted = status == .authorized
    }
}
