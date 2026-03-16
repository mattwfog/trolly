import AppKit

protocol CapturePreviewProviding: Sendable {
    func startPreview(
        source: CaptureSource,
        frameRate: Int,
        maxDimension: CGFloat,
        onFrame: @MainActor @Sendable @escaping (NSImage) -> Void
    ) async throws
    func stopPreview() async throws
}
