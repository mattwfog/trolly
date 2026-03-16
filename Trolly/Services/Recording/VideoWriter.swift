import AVFoundation
import CoreImage
import CoreImage.CIFilterBuiltins
import CoreMedia
import CoreGraphics
import CoreVideo

final class VideoWriter: VideoWriting, @unchecked Sendable {

    // MARK: - Readable State

    private(set) var configuredVideoSize: CGSize = .zero

    // MARK: - Private State

    private var assetWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var audioInput: AVAssetWriterInput?
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    private var outputURL: URL?
    private var hasStartedSession = false

    private var webcamEnabled = false
    private var webcamPosition: WebcamPosition = .bottomLeft
    private var webcamDiameter: CGFloat = 0
    private var latestWebcamImage: CIImage?

    private let writingQueue = DispatchQueue(label: "com.trolly.videowriter")
    private let ciContext = CIContext()

    private static let webcamPadding: CGFloat = 20

    // MARK: - Setup

    func setup(
        outputURL: URL,
        videoSize: CGSize,
        hasWebcam: Bool,
        webcamPosition: WebcamPosition,
        webcamSize: WebcamSize,
        hasAudio: Bool
    ) throws {
        resetState()

        try validateOutputURL(outputURL)
        let writer = try createAssetWriter(url: outputURL)
        let (vidInput, adaptor) = createVideoInput(size: videoSize)

        guard writer.canAdd(vidInput) else {
            throw TrollyError.assetWriterSetupFailed("Cannot add video input")
        }
        writer.add(vidInput)

        if hasAudio {
            let audInput = createAudioInput()
            guard writer.canAdd(audInput) else {
                throw TrollyError.assetWriterSetupFailed("Cannot add audio input")
            }
            writer.add(audInput)
            self.audioInput = audInput
        }

        self.assetWriter = writer
        self.videoInput = vidInput
        self.pixelBufferAdaptor = adaptor
        self.outputURL = outputURL
        self.configuredVideoSize = videoSize
        self.webcamEnabled = hasWebcam
        self.webcamPosition = webcamPosition
        self.webcamDiameter = min(videoSize.width, videoSize.height) * webcamSize.relativeDiameter
    }

    // MARK: - Append Samples

    func appendVideoSample(_ sampleBuffer: CMSampleBuffer) throws {
        guard let writer = assetWriter, let input = videoInput,
              let adaptor = pixelBufferAdaptor else {
            throw TrollyError.assetWriterNotReady
        }

        try startSessionIfNeeded(writer: writer, sampleBuffer: sampleBuffer)

        guard writer.status == .writing else {
            throw TrollyError.assetWriterAppendFailed(
                writer.error?.localizedDescription ?? "Writer not in writing state"
            )
        }

        guard input.isReadyForMoreMediaData else { return }

        let presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)

        guard let sourcePixelBuffer = sampleBuffer.pixelBuffer else {
            throw TrollyError.assetWriterAppendFailed("No pixel buffer in sample")
        }

        if webcamEnabled, let webcamImage = latestWebcamImage {
            try appendComposited(
                sourcePixelBuffer: sourcePixelBuffer,
                webcamImage: webcamImage,
                presentationTime: presentationTime,
                adaptor: adaptor
            )
        } else {
            guard adaptor.append(sourcePixelBuffer, withPresentationTime: presentationTime) else {
                throw TrollyError.assetWriterAppendFailed(
                    writer.error?.localizedDescription ?? "Failed to append pixel buffer"
                )
            }
        }
    }

    func appendWebcamSample(_ sampleBuffer: CMSampleBuffer) throws {
        guard let pixelBuffer = sampleBuffer.pixelBuffer else {
            throw TrollyError.assetWriterAppendFailed("No pixel buffer in webcam sample")
        }
        latestWebcamImage = CIImage(cvPixelBuffer: pixelBuffer)
    }

    func appendAudioSample(_ sampleBuffer: CMSampleBuffer) throws {
        guard let writer = assetWriter, let input = audioInput else {
            throw TrollyError.assetWriterNotReady
        }

        try startSessionIfNeeded(writer: writer, sampleBuffer: sampleBuffer)

        guard writer.status == .writing else {
            throw TrollyError.assetWriterAppendFailed(
                writer.error?.localizedDescription ?? "Writer not in writing state"
            )
        }

        guard input.isReadyForMoreMediaData else { return }

        guard input.append(sampleBuffer) else {
            throw TrollyError.assetWriterAppendFailed(
                writer.error?.localizedDescription ?? "Failed to append audio sample"
            )
        }
    }

    // MARK: - Finish

    func finishWriting() async throws -> URL {
        guard let writer = assetWriter, let url = outputURL else {
            throw TrollyError.assetWriterNotReady
        }

        if hasStartedSession {
            videoInput?.markAsFinished()
            audioInput?.markAsFinished()
        }

        if writer.status == .writing {
            await writer.finishWriting()
        }

        if writer.status == .failed {
            throw TrollyError.assetWriterAppendFailed(
                writer.error?.localizedDescription ?? "Unknown error finishing writing"
            )
        }

        return url
    }

    // MARK: - Webcam Position Calculation

    static func calculateWebcamOrigin(
        position: WebcamPosition,
        videoSize: CGSize,
        webcamDiameter: CGFloat,
        padding: CGFloat
    ) -> CGPoint {
        let x: CGFloat
        let y: CGFloat

        switch position {
        case .bottomLeft:
            x = padding
            y = padding
        case .bottomRight:
            x = videoSize.width - webcamDiameter - padding
            y = padding
        case .topLeft:
            x = padding
            y = videoSize.height - webcamDiameter - padding
        case .topRight:
            x = videoSize.width - webcamDiameter - padding
            y = videoSize.height - webcamDiameter - padding
        }

        return CGPoint(x: x, y: y)
    }
}

// MARK: - Private Helpers

private extension VideoWriter {

    func validateOutputURL(_ url: URL) throws {
        let directory = url.deletingLastPathComponent()
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: directory.path, isDirectory: &isDirectory)

        guard exists, isDirectory.boolValue else {
            throw TrollyError.assetWriterSetupFailed(
                "Output directory does not exist: \(directory.path)"
            )
        }

        guard FileManager.default.isWritableFile(atPath: directory.path) else {
            throw TrollyError.outputDirectoryNotWritable(directory.path)
        }
    }

    func resetState() {
        assetWriter = nil
        videoInput = nil
        audioInput = nil
        pixelBufferAdaptor = nil
        outputURL = nil
        hasStartedSession = false
        configuredVideoSize = .zero
        webcamEnabled = false
        latestWebcamImage = nil
        webcamDiameter = 0
    }

    func createAssetWriter(url: URL) throws -> AVAssetWriter {
        do {
            return try AVAssetWriter(outputURL: url, fileType: .mp4)
        } catch {
            throw TrollyError.assetWriterSetupFailed(error.localizedDescription)
        }
    }

    func createVideoInput(size: CGSize) -> (AVAssetWriterInput, AVAssetWriterInputPixelBufferAdaptor) {
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: Int(size.width),
            AVVideoHeightKey: Int(size.height),
            AVVideoCompressionPropertiesKey: [
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
                AVVideoAverageBitRateKey: 10_000_000,
            ],
        ]

        let input = AVAssetWriterInput(
            mediaType: .video,
            outputSettings: videoSettings
        )
        input.expectsMediaDataInRealTime = true

        let sourcePixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: Int(size.width),
            kCVPixelBufferHeightKey as String: Int(size.height),
        ]

        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input,
            sourcePixelBufferAttributes: sourcePixelBufferAttributes
        )

        return (input, adaptor)
    }

    func createAudioInput() -> AVAssetWriterInput {
        let audioSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2,
            AVEncoderBitRateKey: 128_000,
        ]

        let input = AVAssetWriterInput(
            mediaType: .audio,
            outputSettings: audioSettings
        )
        input.expectsMediaDataInRealTime = true

        return input
    }

    func startSessionIfNeeded(writer: AVAssetWriter, sampleBuffer: CMSampleBuffer) throws {
        guard !hasStartedSession else { return }

        let startTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        guard writer.startWriting() else {
            throw TrollyError.assetWriterAppendFailed(
                writer.error?.localizedDescription ?? "Failed to start writing"
            )
        }
        writer.startSession(atSourceTime: startTime)
        hasStartedSession = true
    }

    func appendComposited(
        sourcePixelBuffer: CVPixelBuffer,
        webcamImage: CIImage,
        presentationTime: CMTime,
        adaptor: AVAssetWriterInputPixelBufferAdaptor
    ) throws {
        let screenImage = CIImage(cvPixelBuffer: sourcePixelBuffer)
        let composited = compositeWebcam(webcamImage, onto: screenImage)

        guard let pool = adaptor.pixelBufferPool else {
            throw TrollyError.assetWriterAppendFailed("Pixel buffer pool not available")
        }

        var outputBuffer: CVPixelBuffer?
        let status = CVPixelBufferPoolCreatePixelBuffer(nil, pool, &outputBuffer)
        guard status == kCVReturnSuccess, let outputPixelBuffer = outputBuffer else {
            throw TrollyError.assetWriterAppendFailed("Failed to create output pixel buffer")
        }

        ciContext.render(composited, to: outputPixelBuffer)

        guard adaptor.append(outputPixelBuffer, withPresentationTime: presentationTime) else {
            throw TrollyError.assetWriterAppendFailed("Failed to append composited frame")
        }
    }

    func compositeWebcam(_ webcamImage: CIImage, onto screenImage: CIImage) -> CIImage {
        let circularWebcam = clipToCircle(webcamImage, diameter: webcamDiameter)
        let origin = Self.calculateWebcamOrigin(
            position: webcamPosition,
            videoSize: configuredVideoSize,
            webcamDiameter: webcamDiameter,
            padding: Self.webcamPadding
        )
        let positioned = circularWebcam.transformed(by: CGAffineTransform(
            translationX: origin.x,
            y: origin.y
        ))

        let composited = positioned.composited(over: screenImage)
        return composited
    }

    func clipToCircle(_ image: CIImage, diameter: CGFloat) -> CIImage {
        let extent = image.extent
        let scaleX = diameter / extent.width
        let scaleY = diameter / extent.height
        let scaled = image.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        let center = CGPoint(x: diameter / 2, y: diameter / 2)
        let radius = diameter / 2

        let maskImage = createCircleMask(center: center, radius: radius, size: diameter)

        let masked = scaled.applyingFilter("CIBlendWithMask", parameters: [
            kCIInputMaskImageKey: maskImage,
        ])

        return masked.cropped(to: CGRect(x: 0, y: 0, width: diameter, height: diameter))
    }

    func createCircleMask(center: CGPoint, radius: CGFloat, size: CGFloat) -> CIImage {
        let radialGradient = CIFilter.radialGradient()
        radialGradient.center = center
        radialGradient.radius0 = Float(radius - 1)
        radialGradient.radius1 = Float(radius)
        radialGradient.color0 = CIColor.white
        radialGradient.color1 = CIColor.clear

        let rect = CGRect(x: 0, y: 0, width: size, height: size)
        return radialGradient.outputImage?.cropped(to: rect) ?? CIImage.empty()
    }
}
