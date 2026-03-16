import AppKit
import Observation

@Observable
@MainActor
final class CapturePreviewViewModel {
    private(set) var previewImage: NSImage?
    private(set) var isLoading: Bool = false
    private(set) var errorMessage: String?

    private let previewService: CapturePreviewProviding
    private var activeSource: CaptureSource?

    init(previewService: CapturePreviewProviding) {
        self.previewService = previewService
    }

    func startPreview(for source: CaptureSource) async {
        if activeSource == source {
            return
        }

        if activeSource != nil {
            await stopPreview()
        }

        activeSource = source
        isLoading = true
        errorMessage = nil

        do {
            var receivedFirstFrame = false
            try await previewService.startPreview(
                source: source,
                frameRate: 8,
                maxDimension: 480,
                onFrame: { [weak self] image in
                    guard let self else { return }
                    self.previewImage = image
                    if !receivedFirstFrame {
                        receivedFirstFrame = true
                        self.isLoading = false
                    }
                }
            )
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }

    func stopPreview() async {
        do {
            try await previewService.stopPreview()
        } catch {
            errorMessage = error.localizedDescription
        }
        previewImage = nil
        activeSource = nil
        isLoading = false
    }
}
