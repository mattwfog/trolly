import SwiftUI
import AVFoundation

struct WebcamPreviewView: NSViewRepresentable {
    let session: AVCaptureSession
    let shape: WebcamShape

    func makeNSView(context: Context) -> WebcamNSView {
        let view = WebcamNSView(webcamShape: shape)
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateNSView(_ nsView: WebcamNSView, context: Context) {
        nsView.previewLayer.session = session
        nsView.webcamShape = shape
        nsView.needsLayout = true
    }
}

final class WebcamNSView: NSView {
    let previewLayer = AVCaptureVideoPreviewLayer()
    var webcamShape: WebcamShape

    init(webcamShape: WebcamShape = .circle) {
        self.webcamShape = webcamShape
        super.init(frame: .zero)
        setupLayer()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func layout() {
        super.layout()
        previewLayer.frame = bounds
        applyMask()
    }

    // MARK: - Private

    private func setupLayer() {
        wantsLayer = true
        layer?.addSublayer(previewLayer)
    }

    private func applyMask() {
        let maskLayer = CAShapeLayer()
        switch webcamShape {
        case .circle:
            let diameter = min(bounds.width, bounds.height)
            let origin = CGPoint(
                x: (bounds.width - diameter) / 2,
                y: (bounds.height - diameter) / 2
            )
            let circleRect = CGRect(origin: origin, size: CGSize(width: diameter, height: diameter))
            maskLayer.path = CGPath(ellipseIn: circleRect, transform: nil)
        case .roundedRect:
            let cornerRadius = min(bounds.width, bounds.height) * 0.15
            maskLayer.path = CGPath(
                roundedRect: bounds,
                cornerWidth: cornerRadius,
                cornerHeight: cornerRadius,
                transform: nil
            )
        }
        previewLayer.mask = maskLayer
    }
}

struct WebcamPreviewContainer: View {
    let session: AVCaptureSession
    let diameter: CGFloat
    let overlaySettings: WebcamOverlaySettings

    var body: some View {
        WebcamPreviewView(session: session, shape: overlaySettings.shape)
            .frame(width: diameter, height: diameter)
            .clipShape(AnyShape(makeShape()))
            .overlay(borderOverlay)
            .opacity(overlaySettings.opacity)
            .shadow(radius: 4)
    }

    private func makeShape() -> some Shape {
        switch overlaySettings.shape {
        case .circle:
            return AnyShape(Circle())
        case .roundedRect:
            return AnyShape(RoundedRectangle(cornerRadius: diameter * 0.15))
        }
    }

    @ViewBuilder
    private var borderOverlay: some View {
        if overlaySettings.showBorder {
            AnyShape(makeShape())
                .stroke(.primary.opacity(0.3), lineWidth: 2)
        }
    }
}

// MARK: - AnyShape (type-erased Shape)

struct AnyShape: Shape {
    private let pathBuilder: @Sendable (CGRect) -> Path

    init<S: Shape>(_ shape: S) {
        pathBuilder = { rect in shape.path(in: rect) }
    }

    func path(in rect: CGRect) -> Path {
        pathBuilder(rect)
    }
}

#Preview {
    WebcamPreviewContainer(
        session: AVCaptureSession(),
        diameter: 120,
        overlaySettings: .default
    )
    .padding()
}
