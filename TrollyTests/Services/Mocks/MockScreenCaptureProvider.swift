import Foundation
import CoreMedia
import ScreenCaptureKit
@testable import Trolly

final class MockScreenCaptureProvider: ScreenCaptureProviding, @unchecked Sendable {
    var availableDisplaysResult: Result<[DisplayInfo], Error> = .success([])
    var availableWindowsResult: Result<[WindowInfo], Error> = .success([])
    var startCaptureError: Error?
    var switchSourceError: Error?
    var stopCaptureError: Error?

    private(set) var startCaptureCallCount = 0
    private(set) var switchSourceCallCount = 0
    private(set) var stopCaptureCallCount = 0
    private(set) var lastCaptureSource: CaptureSource?
    private(set) var lastConfiguration: RecordingConfiguration?
    private(set) var switchedSources: [CaptureSource] = []

    func availableDisplays() async throws -> [DisplayInfo] {
        try availableDisplaysResult.get()
    }

    func availableWindows() async throws -> [WindowInfo] {
        try availableWindowsResult.get()
    }

    func startCapture(
        source: CaptureSource,
        configuration: RecordingConfiguration,
        sampleHandler: @Sendable @escaping (CMSampleBuffer, SCStreamOutputType) -> Void
    ) async throws {
        startCaptureCallCount += 1
        lastCaptureSource = source
        lastConfiguration = configuration
        if let error = startCaptureError {
            throw error
        }
    }

    func switchSource(
        to source: CaptureSource,
        configuration: RecordingConfiguration
    ) async throws {
        switchSourceCallCount += 1
        switchedSources.append(source)
        lastCaptureSource = source
        lastConfiguration = configuration
        if let error = switchSourceError {
            throw error
        }
    }

    func stopCapture() async throws {
        stopCaptureCallCount += 1
        if let error = stopCaptureError {
            throw error
        }
    }
}
