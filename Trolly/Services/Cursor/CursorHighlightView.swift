import AppKit

final class CursorHighlightView: NSView {

    var settings: CursorTrackerSettings = .default {
        didSet { needsDisplay = true }
    }

    private var clickRipples: [ClickRipple] = []
    private var rippleTimer: Timer?

    override var isFlipped: Bool { false }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }

        let center = CGPoint(x: bounds.midX, y: bounds.midY)

        // Draw click ripples (behind highlight)
        for ripple in clickRipples {
            drawClickRipple(context: context, center: center, ripple: ripple)
        }

        // Draw highlight
        switch settings.highlightStyle {
        case .ring:
            drawRing(context: context, center: center)
        case .spotlight:
            drawSpotlight(context: context, center: center)
        }
    }

    // MARK: - Click Ripple

    func triggerClickRipple() {
        let ripple = ClickRipple(startTime: CACurrentMediaTime())
        clickRipples.append(ripple)
        startRippleAnimationIfNeeded()
    }

    // MARK: - Private Drawing

    private func drawRing(context: CGContext, center: CGPoint) {
        let radius = settings.ringSize / 2
        let lineWidth: CGFloat = 3.0
        let color = settings.highlightColor.nsColor
            .withAlphaComponent(settings.highlightOpacity)

        context.setStrokeColor(color.cgColor)
        context.setLineWidth(lineWidth)
        context.addEllipse(in: CGRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        ))
        context.strokePath()
    }

    private func drawSpotlight(context: CGContext, center: CGPoint) {
        let radius = settings.ringSize / 2
        let color = settings.highlightColor.nsColor
            .withAlphaComponent(settings.highlightOpacity * 0.3)

        context.setFillColor(color.cgColor)
        context.addEllipse(in: CGRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        ))
        context.fillPath()

        // Brighter center
        let innerRadius = radius * 0.4
        let innerColor = settings.highlightColor.nsColor
            .withAlphaComponent(settings.highlightOpacity * 0.15)

        context.setFillColor(innerColor.cgColor)
        context.addEllipse(in: CGRect(
            x: center.x - innerRadius,
            y: center.y - innerRadius,
            width: innerRadius * 2,
            height: innerRadius * 2
        ))
        context.fillPath()
    }

    private func drawClickRipple(context: CGContext, center: CGPoint, ripple: ClickRipple) {
        let elapsed = CACurrentMediaTime() - ripple.startTime
        let duration: Double = 0.4
        let progress = min(elapsed / duration, 1.0)

        let maxRadius = settings.ringSize * 0.8
        let radius = maxRadius * progress
        let alpha = (1.0 - progress) * settings.highlightOpacity
        let color = settings.clickColor.nsColor
            .withAlphaComponent(alpha)

        context.setStrokeColor(color.cgColor)
        context.setLineWidth(2.0)
        context.addEllipse(in: CGRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        ))
        context.strokePath()
    }

    // MARK: - Ripple Animation

    private func startRippleAnimationIfNeeded() {
        guard rippleTimer == nil else { return }
        rippleTimer = Timer.scheduledTimer(
            withTimeInterval: 1.0 / 60.0,
            repeats: true
        ) { [weak self] _ in
            guard let self else { return }
            DispatchQueue.main.async {
                self.clickRipples.removeAll { ripple in
                    CACurrentMediaTime() - ripple.startTime > 0.4
                }
                if self.clickRipples.isEmpty {
                    self.rippleTimer?.invalidate()
                    self.rippleTimer = nil
                }
                self.needsDisplay = true
            }
        }
    }
}

// MARK: - ClickRipple

private struct ClickRipple {
    let startTime: CFTimeInterval
}

// MARK: - CursorHighlightColor + NSColor

extension CursorHighlightColor {
    var nsColor: NSColor {
        switch self {
        case .yellow: return .systemYellow
        case .red: return .systemRed
        case .blue: return .systemBlue
        case .green: return .systemGreen
        case .white: return .white
        }
    }
}
