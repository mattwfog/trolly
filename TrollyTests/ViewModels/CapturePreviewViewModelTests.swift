import Testing
import AppKit
@testable import Trolly

@Suite("CapturePreviewViewModel")
struct CapturePreviewViewModelTests {

    // MARK: - Helpers

    private static let testDisplay = DisplayInfo(
        id: 1,
        displayName: "Test Display",
        width: 1920,
        height: 1080
    )
    private static let testSource = CaptureSource.fullScreen(display: testDisplay)

    private static let altDisplay = DisplayInfo(
        id: 2,
        displayName: "External Display",
        width: 2560,
        height: 1440
    )
    private static let altSource = CaptureSource.fullScreen(display: altDisplay)

    @MainActor
    private static func makeSUT() -> (
        viewModel: CapturePreviewViewModel,
        service: MockCapturePreviewProvider
    ) {
        let service = MockCapturePreviewProvider()
        let viewModel = CapturePreviewViewModel(previewService: service)
        return (viewModel, service)
    }

    // MARK: - startPreview calls service

    @Test("startPreview calls service with correct parameters")
    @MainActor
    func startPreview_callsService() async {
        let (viewModel, service) = Self.makeSUT()

        await viewModel.startPreview(for: Self.testSource)

        #expect(service.startPreviewCallCount == 1)
        #expect(service.lastSource == Self.testSource)
        #expect(service.lastFrameRate == 8)
        #expect(service.lastMaxDimension == 480)
    }

    // MARK: - startPreview sets isLoading

    @Test("startPreview sets isLoading to true")
    @MainActor
    func startPreview_setsIsLoading() async {
        let (viewModel, _) = Self.makeSUT()

        await viewModel.startPreview(for: Self.testSource)

        #expect(viewModel.isLoading == true)
    }

    // MARK: - stopPreview clears image

    @Test("stopPreview clears previewImage and activeSource")
    @MainActor
    func stopPreview_clearsImage() async {
        let (viewModel, service) = Self.makeSUT()

        await viewModel.startPreview(for: Self.testSource)
        service.simulateFrame(NSImage(size: NSSize(width: 100, height: 100)))
        #expect(viewModel.previewImage != nil)

        await viewModel.stopPreview()

        #expect(viewModel.previewImage == nil)
        #expect(viewModel.isLoading == false)
    }

    // MARK: - changing source stops old and starts new

    @Test("changing source stops previous preview and starts new one")
    @MainActor
    func changingSource_stopsOldStartsNew() async {
        let (viewModel, service) = Self.makeSUT()

        await viewModel.startPreview(for: Self.testSource)
        #expect(service.startPreviewCallCount == 1)

        await viewModel.startPreview(for: Self.altSource)

        #expect(service.stopPreviewCallCount == 1)
        #expect(service.startPreviewCallCount == 2)
        #expect(service.lastSource == Self.altSource)
    }

    // MARK: - service error sets errorMessage

    @Test("service error sets errorMessage")
    @MainActor
    func serviceError_setsErrorMessage() async {
        let (viewModel, service) = Self.makeSUT()
        service.startPreviewError = NSError(
            domain: "test",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Preview failed"]
        )

        await viewModel.startPreview(for: Self.testSource)

        #expect(viewModel.errorMessage == "Preview failed")
        #expect(viewModel.isLoading == false)
    }

    // MARK: - same source skips restart

    @Test("startPreview with same source skips restart")
    @MainActor
    func sameSource_skipsRestart() async {
        let (viewModel, service) = Self.makeSUT()

        await viewModel.startPreview(for: Self.testSource)
        await viewModel.startPreview(for: Self.testSource)

        #expect(service.startPreviewCallCount == 1)
        #expect(service.stopPreviewCallCount == 0)
    }
}
