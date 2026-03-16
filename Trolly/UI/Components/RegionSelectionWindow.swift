import AppKit
import CoreGraphics

enum RegionSelectionWindow {

    private static let minimumSelectionSize: CGFloat = 100

    static func selectRegion(on display: DisplayInfo) async -> CGRect? {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                let screenFrame = screenFrame(for: display)
                let window = createOverlayWindow(frame: screenFrame)
                let selectionView = RegionSelectionView(
                    frame: screenFrame,
                    onComplete: { rect in
                        window.orderOut(nil)
                        continuation.resume(returning: rect)
                    }
                )
                window.contentView = selectionView
                window.makeKeyAndOrderFront(nil)
                window.makeFirstResponder(selectionView)
            }
        }
    }

    private static func screenFrame(for display: DisplayInfo) -> NSRect {
        let screens = NSScreen.screens
        let matched = screens.first { screen in
            let screenNumber = screen.deviceDescription[
                NSDeviceDescriptionKey("NSScreenNumber")
            ] as? CGDirectDisplayID
            return screenNumber == display.id
        }
        return matched?.frame ?? (screens.first?.frame ?? .zero)
    }

    private static func createOverlayWindow(frame: NSRect) -> NSWindow {
        let window = NSWindow(
            contentRect: frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.level = .screenSaver
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = false
        window.acceptsMouseMovedEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        return window
    }
}

// MARK: - Region Selection View

private final class RegionSelectionView: NSView {

    private let onComplete: (CGRect?) -> Void
    private var dragOrigin: NSPoint?
    private var currentRect: NSRect?
    private let overlayColor = NSColor.black.withAlphaComponent(0.3)
    private let borderColor = NSColor.white
    private let borderWidth: CGFloat = 2.0
    private let minimumSize: CGFloat = 100

    init(frame: NSRect, onComplete: @escaping (CGRect?) -> Void) {
        self.onComplete = onComplete
        super.init(frame: frame)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }

    // MARK: - Responder

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape
            onComplete(nil)
        }
    }

    // MARK: - Mouse Events

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        dragOrigin = point
        currentRect = nil
        setNeedsDisplay(bounds)
    }

    override func mouseDragged(with event: NSEvent) {
        guard let origin = dragOrigin else { return }
        let point = convert(event.locationInWindow, from: nil)
        currentRect = rectFromPoints(origin, point)
        setNeedsDisplay(bounds)
    }

    override func mouseUp(with event: NSEvent) {
        guard let rect = currentRect else {
            onComplete(nil)
            return
        }

        if rect.width < minimumSize || rect.height < minimumSize {
            onComplete(nil)
            return
        }

        let screenRect = convertToScreenCoordinates(rect)
        onComplete(screenRect)
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        drawOverlay()
        guard let selection = currentRect else { return }
        clearSelectionArea(selection)
        drawSelectionBorder(selection)
        drawDimensionsLabel(selection)
    }

    private func drawOverlay() {
        overlayColor.setFill()
        bounds.fill()
    }

    private func clearSelectionArea(_ selection: NSRect) {
        NSColor.clear.setFill()
        selection.fill(using: .copy)
    }

    private func drawSelectionBorder(_ selection: NSRect) {
        let path = NSBezierPath(rect: selection)
        path.lineWidth = borderWidth
        borderColor.setStroke()
        path.stroke()
    }

    private func drawDimensionsLabel(_ selection: NSRect) {
        let screenRect = convertToScreenCoordinates(selection)
        let labelText = "\(Int(screenRect.width)) x \(Int(screenRect.height))"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 13, weight: .medium),
            .foregroundColor: NSColor.white,
            .backgroundColor: NSColor.black.withAlphaComponent(0.7)
        ]
        let attributedString = NSAttributedString(
            string: "  \(labelText)  ",
            attributes: attributes
        )
        let labelSize = attributedString.size()
        let labelOrigin = NSPoint(
            x: min(selection.maxX - labelSize.width, bounds.maxX - labelSize.width - 8),
            y: max(selection.minY - labelSize.height - 6, bounds.minY + 4)
        )
        attributedString.draw(at: labelOrigin)
    }

    // MARK: - Coordinate Helpers

    private func rectFromPoints(_ a: NSPoint, _ b: NSPoint) -> NSRect {
        let x = min(a.x, b.x)
        let y = min(a.y, b.y)
        let width = abs(a.x - b.x)
        let height = abs(a.y - b.y)
        return NSRect(x: x, y: y, width: width, height: height)
    }

    private func convertToScreenCoordinates(_ viewRect: NSRect) -> CGRect {
        guard let windowFrame = window?.frame else { return viewRect }

        // Convert from view coordinates (origin bottom-left) to
        // screen coordinates with origin at the top-left of the display,
        // which is what ScreenCaptureKit expects.
        let screenX = viewRect.origin.x
        let screenY = windowFrame.height - viewRect.origin.y - viewRect.height
        return CGRect(
            x: screenX,
            y: screenY,
            width: viewRect.width,
            height: viewRect.height
        )
    }
}
