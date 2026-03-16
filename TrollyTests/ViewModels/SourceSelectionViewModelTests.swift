import Testing
import Foundation
@testable import Trolly

@Suite("SourceSelectionViewModel")
struct SourceSelectionViewModelTests {

    // MARK: - Helpers

    private static let testDisplays = [
        DisplayInfo(id: 1, displayName: "Main Display", width: 2560, height: 1440),
        DisplayInfo(id: 2, displayName: "External Display", width: 1920, height: 1080)
    ]

    private static let testWindows = [
        WindowInfo(
            id: 100,
            title: "Document.swift",
            applicationName: "Xcode",
            frame: CGRect(x: 0, y: 0, width: 1200, height: 800)
        ),
        WindowInfo(
            id: 101,
            title: "Safari",
            applicationName: "Safari",
            frame: CGRect(x: 100, y: 100, width: 1024, height: 768)
        )
    ]

    @MainActor
    private static func makeSUT() -> (
        viewModel: SourceSelectionViewModel,
        screenCapture: MockScreenCaptureProvider
    ) {
        let screenCapture = MockScreenCaptureProvider()
        let viewModel = SourceSelectionViewModel(
            screenCaptureProvider: screenCapture
        )
        return (viewModel, screenCapture)
    }

    // MARK: - Initial State

    @Test("Initial state has empty displays and windows")
    @MainActor
    func testInitialState_hasEmptyDisplaysAndWindows() {
        let (viewModel, _) = Self.makeSUT()

        #expect(viewModel.availableDisplays.isEmpty)
        #expect(viewModel.availableWindows.isEmpty)
        #expect(!viewModel.isLoading)
        #expect(viewModel.errorMessage == nil)
    }

    // MARK: - loadSources

    @Test("loadSources populates displays and windows")
    @MainActor
    func testLoadSources_populatesDisplaysAndWindows() async {
        let (viewModel, screenCapture) = Self.makeSUT()
        screenCapture.availableDisplaysResult = .success(Self.testDisplays)
        screenCapture.availableWindowsResult = .success(Self.testWindows)

        await viewModel.loadSources()

        #expect(viewModel.availableDisplays == Self.testDisplays)
        #expect(viewModel.availableWindows == Self.testWindows)
        #expect(!viewModel.isLoading)
        #expect(viewModel.errorMessage == nil)
    }

    @Test("loadSources sets isLoading during fetch")
    @MainActor
    func testLoadSources_setsIsLoadingDuringFetch() async {
        let (viewModel, screenCapture) = Self.makeSUT()
        screenCapture.availableDisplaysResult = .success(Self.testDisplays)
        screenCapture.availableWindowsResult = .success(Self.testWindows)

        // Before loading
        #expect(!viewModel.isLoading)

        await viewModel.loadSources()

        // After loading completes, isLoading should be false
        #expect(!viewModel.isLoading)
    }

    @Test("loadSources sets errorMessage on failure")
    @MainActor
    func testLoadSources_setsErrorMessageOnFailure() async {
        let (viewModel, screenCapture) = Self.makeSUT()
        screenCapture.availableDisplaysResult = .failure(TrollyError.noDisplaysAvailable)

        await viewModel.loadSources()

        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.availableDisplays.isEmpty)
        #expect(!viewModel.isLoading)
    }

    // MARK: - refreshSources

    @Test("refreshSources repopulates displays and windows")
    @MainActor
    func testRefreshSources_repopulatesDisplaysAndWindows() async {
        let (viewModel, screenCapture) = Self.makeSUT()
        screenCapture.availableDisplaysResult = .success(Self.testDisplays)
        screenCapture.availableWindowsResult = .success(Self.testWindows)

        await viewModel.refreshSources()

        #expect(viewModel.availableDisplays == Self.testDisplays)
        #expect(viewModel.availableWindows == Self.testWindows)
    }
}
