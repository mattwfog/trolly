import AppKit

@MainActor
final class CursorTracker {

    private var overlayWindow: CursorOverlayWindow?
    private var positionTimer: Timer?
    private var clickMonitor: Any?
    private var settings: CursorTrackerSettings = .default

    private(set) var isTracking: Bool = false

    func start(with settings: CursorTrackerSettings) {
        guard settings.enabled else { return }
        guard !isTracking else {
            updateSettings(settings)
            return
        }

        self.settings = settings
        let overlay = CursorOverlayWindow(settings: settings)
        overlay.moveToMousePosition()
        overlay.orderFrontRegardless()
        self.overlayWindow = overlay
        isTracking = true

        startPositionTracking()
        startClickMonitoring()
    }

    func stop() {
        stopPositionTracking()
        stopClickMonitoring()
        overlayWindow?.orderOut(nil)
        overlayWindow = nil
        isTracking = false
    }

    func updateSettings(_ settings: CursorTrackerSettings) {
        self.settings = settings
        if !settings.enabled {
            stop()
            return
        }
        if isTracking {
            overlayWindow?.updateSettings(settings)
        } else {
            start(with: settings)
        }
    }

    // MARK: - Position Tracking

    private func startPositionTracking() {
        positionTimer = Timer.scheduledTimer(
            withTimeInterval: 1.0 / 60.0,
            repeats: true
        ) { [weak self] _ in
            DispatchQueue.main.async { [weak self] in
                self?.overlayWindow?.moveToMousePosition()
            }
        }
    }

    private func stopPositionTracking() {
        positionTimer?.invalidate()
        positionTimer = nil
    }

    // MARK: - Click Monitoring

    private func startClickMonitoring() {
        guard settings.clickEffectEnabled else { return }

        clickMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] _ in
            DispatchQueue.main.async { [weak self] in
                self?.overlayWindow?.highlightView.triggerClickRipple()
            }
        }
    }

    private func stopClickMonitoring() {
        if let monitor = clickMonitor {
            NSEvent.removeMonitor(monitor)
        }
        clickMonitor = nil
    }
}
