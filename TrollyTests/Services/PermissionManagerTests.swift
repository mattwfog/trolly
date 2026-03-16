import Testing
import AVFoundation
@testable import Trolly

@Suite("PermissionManager")
@MainActor
struct PermissionManagerTests {

    @Test("Initial state has all permissions false")
    func initialState() {
        let manager = PermissionManager(
            screenCaptureChecker: { false },
            screenCaptureRequester: { false },
            avAuthorizationStatus: { _ in .notDetermined },
            avRequestAccess: { _ in false }
        )

        #expect(manager.screenCaptureGranted == false)
        #expect(manager.cameraGranted == false)
        #expect(manager.microphoneGranted == false)
    }

    @Test("checkAllPermissions updates all states when granted")
    func checkAllPermissionsGranted() async {
        let manager = PermissionManager(
            screenCaptureChecker: { true },
            screenCaptureRequester: { true },
            avAuthorizationStatus: { _ in .authorized },
            avRequestAccess: { _ in true }
        )

        await manager.checkAllPermissions()

        #expect(manager.screenCaptureGranted == true)
        #expect(manager.cameraGranted == true)
        #expect(manager.microphoneGranted == true)
    }

    @Test("checkAllPermissions updates all states when denied")
    func checkAllPermissionsDenied() async {
        let manager = PermissionManager(
            screenCaptureChecker: { false },
            screenCaptureRequester: { false },
            avAuthorizationStatus: { _ in .denied },
            avRequestAccess: { _ in false }
        )

        await manager.checkAllPermissions()

        #expect(manager.screenCaptureGranted == false)
        #expect(manager.cameraGranted == false)
        #expect(manager.microphoneGranted == false)
    }

    @Test("checkAllPermissions handles mixed permission states")
    func checkAllPermissionsMixed() async {
        let manager = PermissionManager(
            screenCaptureChecker: { true },
            screenCaptureRequester: { true },
            avAuthorizationStatus: { mediaType in
                mediaType == .video ? .authorized : .denied
            },
            avRequestAccess: { _ in false }
        )

        await manager.checkAllPermissions()

        #expect(manager.screenCaptureGranted == true)
        #expect(manager.cameraGranted == true)
        #expect(manager.microphoneGranted == false)
    }

    @Test("requestScreenCapturePermission sets granted on success")
    func requestScreenCaptureGranted() async throws {
        let manager = PermissionManager(
            screenCaptureChecker: { false },
            screenCaptureRequester: { true },
            avAuthorizationStatus: { _ in .notDetermined },
            avRequestAccess: { _ in false }
        )

        try await manager.requestScreenCapturePermission()

        #expect(manager.screenCaptureGranted == true)
    }

    @Test("requestScreenCapturePermission throws on denial")
    func requestScreenCaptureDenied() async {
        let manager = PermissionManager(
            screenCaptureChecker: { false },
            screenCaptureRequester: { false },
            avAuthorizationStatus: { _ in .notDetermined },
            avRequestAccess: { _ in false }
        )

        await #expect(throws: TrollyError.screenCapturePermissionDenied) {
            try await manager.requestScreenCapturePermission()
        }

        #expect(manager.screenCaptureGranted == false)
    }

    @Test("requestCameraPermission returns true when granted")
    func requestCameraGranted() async {
        let manager = PermissionManager(
            screenCaptureChecker: { false },
            screenCaptureRequester: { false },
            avAuthorizationStatus: { _ in .notDetermined },
            avRequestAccess: { mediaType in
                mediaType == .video
            }
        )

        let result = await manager.requestCameraPermission()

        #expect(result == true)
        #expect(manager.cameraGranted == true)
    }

    @Test("requestCameraPermission returns false when denied")
    func requestCameraDenied() async {
        let manager = PermissionManager(
            screenCaptureChecker: { false },
            screenCaptureRequester: { false },
            avAuthorizationStatus: { _ in .notDetermined },
            avRequestAccess: { _ in false }
        )

        let result = await manager.requestCameraPermission()

        #expect(result == false)
        #expect(manager.cameraGranted == false)
    }

    @Test("requestMicrophonePermission returns true when granted")
    func requestMicrophoneGranted() async {
        let manager = PermissionManager(
            screenCaptureChecker: { false },
            screenCaptureRequester: { false },
            avAuthorizationStatus: { _ in .notDetermined },
            avRequestAccess: { mediaType in
                mediaType == .audio
            }
        )

        let result = await manager.requestMicrophonePermission()

        #expect(result == true)
        #expect(manager.microphoneGranted == true)
    }

    @Test("requestMicrophonePermission returns false when denied")
    func requestMicrophoneDenied() async {
        let manager = PermissionManager(
            screenCaptureChecker: { false },
            screenCaptureRequester: { false },
            avAuthorizationStatus: { _ in .notDetermined },
            avRequestAccess: { _ in false }
        )

        let result = await manager.requestMicrophonePermission()

        #expect(result == false)
        #expect(manager.microphoneGranted == false)
    }

    @Test("Camera check treats restricted status as not granted")
    func cameraRestrictedNotGranted() async {
        let manager = PermissionManager(
            screenCaptureChecker: { false },
            screenCaptureRequester: { false },
            avAuthorizationStatus: { _ in .restricted },
            avRequestAccess: { _ in false }
        )

        await manager.checkAllPermissions()

        #expect(manager.cameraGranted == false)
        #expect(manager.microphoneGranted == false)
    }
}
