import Testing
import Foundation
import CoreGraphics
@testable import Trolly

@Suite("CaptureSource")
struct CaptureSourceTests {

    static let testDisplay = DisplayInfo(
        id: 1,
        displayName: "Built-in Display",
        width: 2560,
        height: 1600
    )

    static let testWindow = WindowInfo(
        id: 42,
        title: "Document.swift",
        applicationName: "Xcode",
        frame: CGRect(x: 0, y: 0, width: 1200, height: 800)
    )

    @Test("Full screen display name")
    func fullScreenDisplayName() {
        let source = CaptureSource.fullScreen(display: CaptureSourceTests.testDisplay)

        #expect(source.displayName == "Built-in Display")
    }

    @Test("Window display name includes app and title")
    func windowDisplayName() {
        let source = CaptureSource.window(window: CaptureSourceTests.testWindow)

        #expect(source.displayName == "Xcode - Document.swift")
    }

    @Test("Full screen resolution matches display dimensions")
    func fullScreenResolution() {
        let source = CaptureSource.fullScreen(display: CaptureSourceTests.testDisplay)

        #expect(source.resolution == CGSize(width: 2560, height: 1600))
    }

    @Test("Window resolution matches window frame size")
    func windowResolution() {
        let source = CaptureSource.window(window: CaptureSourceTests.testWindow)

        #expect(source.resolution == CGSize(width: 1200, height: 800))
    }

    @Test("DisplayInfo is identifiable by CGDirectDisplayID")
    func displayInfoIdentifiable() {
        let display = CaptureSourceTests.testDisplay

        #expect(display.id == 1)
    }

    @Test("WindowInfo is identifiable by CGWindowID")
    func windowInfoIdentifiable() {
        let window = CaptureSourceTests.testWindow

        #expect(window.id == 42)
    }

    @Test("CaptureSource equality for same display")
    func fullScreenEquality() {
        let a = CaptureSource.fullScreen(display: CaptureSourceTests.testDisplay)
        let b = CaptureSource.fullScreen(display: CaptureSourceTests.testDisplay)

        #expect(a == b)
    }

    @Test("CaptureSource inequality for different types")
    func differentTypeInequality() {
        let a = CaptureSource.fullScreen(display: CaptureSourceTests.testDisplay)
        let b = CaptureSource.window(window: CaptureSourceTests.testWindow)

        #expect(a != b)
    }
}
