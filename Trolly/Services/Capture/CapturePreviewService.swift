import AppKit
import CoreImage
import CoreMedia
import ScreenCaptureKit

final class CapturePreviewService: CapturePreviewProviding, @unchecked Sendable {

    // MARK: - Private State

    private var stream: SCStream?
    private var streamOutput: PreviewOutputHandler?
    private let ciContext: CIContext

    // MARK: - Init

    init() {
        self.ciContext = CIContext(options: [.useSoftwareRenderer: false])
    }

    // MARK: - Preview Control

    func startPreview(
        source: CaptureSource,
        frameRate: Int,
        maxDimension: CGFloat,
        onFrame: @MainActor @Sendable @escaping (NSImage) -> Void
    ) async throws {
        try await stopPreview()

        let filter = try await buildContentFilter(for: source)
        let streamConfig = buildPreviewConfiguration(
            source: source,
            frameRate: frameRate,
            maxDimension: maxDimension
        )

        let captureStream = SCStream(filter: filter, configuration: streamConfig, delegate: nil)

        let outputHandler = PreviewOutputHandler(
            ciContext: ciContext,
            onFrame: onFrame
        )
        try captureStream.addStreamOutput(
            outputHandler,
            type: .screen,
            sampleHandlerQueue: DispatchQueue(label: "com.trolly.preview-capture")
        )

        do {
            try await captureStream.startCapture()
        } catch {
            throw TrollyError.previewStreamFailed(error.localizedDescription)
        }

        self.stream = captureStream
        self.streamOutput = outputHandler
    }

    func stopPreview() async throws {
        guard let activeStream = stream else { return }

        do {
            try await activeStream.stopCapture()
        } catch {
            throw TrollyError.previewStreamFailed(error.localizedDescription)
        }

        stream = nil
        streamOutput = nil
    }

    // MARK: - Private Helpers

    private func buildContentFilter(
        for source: CaptureSource
    ) async throws -> SCContentFilter {
        switch source {
        case .fullScreen(let display), .region(let display, _):
            let content = try await SCShareableContent.excludingDesktopWindows(
                false,
                onScreenWindowsOnly: false
            )
            guard let scDisplay = content.displays.first(
                where: { $0.displayID == display.id }
            ) else {
                throw TrollyError.noDisplaysAvailable
            }
            return SCContentFilter(display: scDisplay, excludingWindows: [])

        case .window(let window):
            let content = try await SCShareableContent.excludingDesktopWindows(
                true,
                onScreenWindowsOnly: true
            )
            guard let scWindow = content.windows.first(
                where: { $0.windowID == window.id }
            ) else {
                throw TrollyError.noWindowsAvailable
            }
            return SCContentFilter(desktopIndependentWindow: scWindow)
        }
    }

    private func buildPreviewConfiguration(
        source: CaptureSource,
        frameRate: Int,
        maxDimension: CGFloat
    ) -> SCStreamConfiguration {
        let streamConfig = SCStreamConfiguration()

        let sourceSize = source.resolution
        let scaled = scaledSize(from: sourceSize, maxDimension: maxDimension)
        streamConfig.width = Int(scaled.width)
        streamConfig.height = Int(scaled.height)

        if case .region(_, let rect) = source {
            streamConfig.sourceRect = rect
        }

        streamConfig.minimumFrameInterval = CMTime(
            value: 1,
            timescale: CMTimeScale(frameRate)
        )

        streamConfig.showsCursor = true
        streamConfig.capturesAudio = false
        streamConfig.pixelFormat = kCVPixelFormatType_32BGRA

        return streamConfig
    }

    private func scaledSize(from source: CGSize, maxDimension: CGFloat) -> CGSize {
        let maxSide = max(source.width, source.height)
        guard maxSide > 0 else {
            return CGSize(width: maxDimension, height: maxDimension)
        }

        let scale = maxDimension / maxSide
        let width = (source.width * scale).rounded(.down)
        let height = (source.height * scale).rounded(.down)

        return CGSize(
            width: max(width, 1),
            height: max(height, 1)
        )
    }
}

// MARK: - Preview Output Handler

private final class PreviewOutputHandler: NSObject, SCStreamOutput, @unchecked Sendable {

    private let ciContext: CIContext
    private let onFrame: @MainActor @Sendable (NSImage) -> Void

    init(
        ciContext: CIContext,
        onFrame: @MainActor @Sendable @escaping (NSImage) -> Void
    ) {
        self.ciContext = ciContext
        self.onFrame = onFrame
        super.init()
    }

    func stream(
        _ stream: SCStream,
        didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
        of type: SCStreamOutputType
    ) {
        guard type == .screen else { return }
        guard let pixelBuffer = sampleBuffer.pixelBuffer else { return }

        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let extent = ciImage.extent

        guard let cgImage = ciContext.createCGImage(ciImage, from: extent) else { return }

        let nsImage = NSImage(
            cgImage: cgImage,
            size: NSSize(width: extent.width, height: extent.height)
        )

        let callback = onFrame
        Task { @MainActor in
            callback(nsImage)
        }
    }
}
