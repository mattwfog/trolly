import AppKit
@testable import Trolly

final class MockCapturePreviewProvider: CapturePreviewProviding, @unchecked Sendable {
    var startPreviewError: Error?
    var stopPreviewError: Error?

    private(set) var startPreviewCallCount = 0
    private(set) var stopPreviewCallCount = 0
    private(set) var lastSource: CaptureSource?
    private(set) var lastFrameRate: Int?
    private(set) var lastMaxDimension: CGFloat?

    private var storedOnFrame: (@MainActor @Sendable (NSImage) -> Void)?

    func startPreview(
        source: CaptureSource,
        frameRate: Int,
        maxDimension: CGFloat,
        onFrame: @MainActor @Sendable @escaping (NSImage) -> Void
    ) async throws {
        startPreviewCallCount += 1
        lastSource = source
        lastFrameRate = frameRate
        lastMaxDimension = maxDimension
        storedOnFrame = onFrame
        if let error = startPreviewError {
            throw error
        }
    }

    func stopPreview() async throws {
        stopPreviewCallCount += 1
        storedOnFrame = nil
        if let error = stopPreviewError {
            throw error
        }
    }

    @MainActor
    func simulateFrame(_ image: NSImage) {
        storedOnFrame?(image)
    }
}
