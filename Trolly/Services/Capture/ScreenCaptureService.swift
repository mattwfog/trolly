import Foundation
import CoreMedia
import ScreenCaptureKit

final class ScreenCaptureService: ScreenCaptureProviding, @unchecked Sendable {

    // MARK: - Private State

    private var stream: SCStream?
    private var streamOutput: StreamOutputHandler?

    // MARK: - Available Sources

    func availableDisplays() async throws -> [DisplayInfo] {
        let content: SCShareableContent
        do {
            content = try await SCShareableContent.excludingDesktopWindows(
                false,
                onScreenWindowsOnly: false
            )
        } catch {
            throw TrollyError.captureStreamFailed(error.localizedDescription)
        }

        return content.displays.map { display in
            DisplayInfo(
                id: display.displayID,
                displayName: "Display \(display.displayID)",
                width: display.width,
                height: display.height
            )
        }
    }

    func availableWindows() async throws -> [WindowInfo] {
        let content: SCShareableContent
        do {
            content = try await SCShareableContent.excludingDesktopWindows(
                true,
                onScreenWindowsOnly: true
            )
        } catch {
            throw TrollyError.captureStreamFailed(error.localizedDescription)
        }

        let minimumDimension: CGFloat = 100

        return content.windows.compactMap { window in
            guard let title = window.title, !title.isEmpty else { return nil }
            guard window.frame.width >= minimumDimension,
                  window.frame.height >= minimumDimension else { return nil }

            return WindowInfo(
                id: window.windowID,
                title: title,
                applicationName: window.owningApplication?.applicationName ?? "Unknown",
                frame: window.frame
            )
        }
    }

    // MARK: - Capture Control

    func startCapture(
        source: CaptureSource,
        configuration: RecordingConfiguration,
        sampleHandler: @Sendable @escaping (CMSampleBuffer, SCStreamOutputType) -> Void
    ) async throws {
        let filter = try await buildContentFilter(for: source)
        let streamConfig = buildStreamConfiguration(
            source: source,
            configuration: configuration
        )

        let captureStream = SCStream(filter: filter, configuration: streamConfig, delegate: nil)

        let outputHandler = StreamOutputHandler(handler: sampleHandler)
        try captureStream.addStreamOutput(
            outputHandler,
            type: .screen,
            sampleHandlerQueue: DispatchQueue(label: "com.trolly.screen-capture")
        )

        do {
            try await captureStream.startCapture()
        } catch {
            throw TrollyError.captureStreamFailed(error.localizedDescription)
        }

        self.stream = captureStream
        self.streamOutput = outputHandler
    }

    func switchSource(
        to source: CaptureSource,
        configuration: RecordingConfiguration
    ) async throws {
        guard let activeStream = stream else {
            throw TrollyError.captureStreamFailed("No active stream to switch")
        }

        let newFilter = try await buildContentFilter(for: source)
        let newConfig = buildStreamConfiguration(source: source, configuration: configuration)

        do {
            try await activeStream.updateContentFilter(newFilter)
            try await activeStream.updateConfiguration(newConfig)
        } catch {
            throw TrollyError.captureStreamFailed(
                "Failed to switch source: \(error.localizedDescription)"
            )
        }
    }

    func stopCapture() async throws {
        guard let activeStream = stream else { return }

        do {
            try await activeStream.stopCapture()
        } catch {
            throw TrollyError.captureStreamFailed(error.localizedDescription)
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

    private func buildStreamConfiguration(
        source: CaptureSource,
        configuration: RecordingConfiguration
    ) -> SCStreamConfiguration {
        let streamConfig = SCStreamConfiguration()

        let resolution = configuration.captureResolution ?? source.resolution
        streamConfig.width = Int(resolution.width)
        streamConfig.height = Int(resolution.height)

        if case .region(_, let rect) = source {
            streamConfig.sourceRect = rect
            streamConfig.width = Int(rect.width)
            streamConfig.height = Int(rect.height)
        }

        let frameRate = configuration.captureFrameRate
        streamConfig.minimumFrameInterval = CMTime(
            value: 1,
            timescale: CMTimeScale(frameRate)
        )

        streamConfig.showsCursor = true
        streamConfig.capturesAudio = false
        streamConfig.pixelFormat = kCVPixelFormatType_32BGRA

        return streamConfig
    }
}

// MARK: - Stream Output Handler

private final class StreamOutputHandler: NSObject, SCStreamOutput, @unchecked Sendable {

    private let handler: @Sendable (CMSampleBuffer, SCStreamOutputType) -> Void

    init(handler: @Sendable @escaping (CMSampleBuffer, SCStreamOutputType) -> Void) {
        self.handler = handler
        super.init()
    }

    func stream(
        _ stream: SCStream,
        didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
        of type: SCStreamOutputType
    ) {
        handler(sampleBuffer, type)
    }
}
