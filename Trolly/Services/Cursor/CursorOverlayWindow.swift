import AppKit

final class CursorOverlayWindow: NSWindow {

    let highlightView: CursorHighlightView

    init(settings: CursorTrackerSettings) {
        let size = settings.ringSize * 2.5
        let frame = NSRect(x: 0, y: 0, width: size, height: size)

        self.highlightView = CursorHighlightView(frame: frame)
        highlightView.settings = settings

        super.init(
            contentRect: frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = true
        level = .screenSaver
        collectionBehavior = [.canJoinAllSpaces, .stationary]

        contentView = highlightView
    }

    func updateSettings(_ settings: CursorTrackerSettings) {
        let size = settings.ringSize * 2.5
        setContentSize(NSSize(width: size, height: size))
        highlightView.frame = NSRect(x: 0, y: 0, width: size, height: size)
        highlightView.settings = settings
    }

    func moveToMousePosition() {
        let mouseLocation = NSEvent.mouseLocation
        let size = frame.size
        let origin = NSPoint(
            x: mouseLocation.x - size.width / 2,
            y: mouseLocation.y - size.height / 2
        )
        setFrameOrigin(origin)
    }
}
