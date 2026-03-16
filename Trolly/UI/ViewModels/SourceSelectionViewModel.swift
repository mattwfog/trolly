import Foundation
import Observation

@Observable
@MainActor
final class SourceSelectionViewModel {
    private let screenCaptureProvider: ScreenCaptureProviding

    private(set) var availableDisplays: [DisplayInfo] = []
    private(set) var availableWindows: [WindowInfo] = []
    private(set) var isLoading: Bool = false
    private(set) var errorMessage: String?

    init(screenCaptureProvider: ScreenCaptureProviding) {
        self.screenCaptureProvider = screenCaptureProvider
    }

    // MARK: - Actions

    func loadSources() async {
        isLoading = true
        errorMessage = nil

        do {
            let displays = try await screenCaptureProvider.availableDisplays()
            let windows = try await screenCaptureProvider.availableWindows()
            availableDisplays = displays
            availableWindows = windows
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func refreshSources() async {
        await loadSources()
    }
}
