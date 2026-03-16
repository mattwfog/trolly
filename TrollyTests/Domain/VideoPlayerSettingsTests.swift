import Testing
import Foundation
@testable import Trolly

@Suite("VideoPlayerSettings")
struct VideoPlayerSettingsTests {

    // MARK: - Defaults

    @Test("default settings have expected values")
    func testDefaults() {
        let settings = VideoPlayerSettings.default

        #expect(settings.transcriptPosition == .right)
        #expect(settings.transcriptPanelSize == .medium)
        #expect(settings.transcriptAutoScroll == true)
        #expect(settings.transcriptVisibleByDefault == true)
        #expect(settings.transcriptFontSize == .medium)
        #expect(settings.transcriptShowTimestamps == true)
        #expect(settings.timestampFormat == .minuteSecond)
        #expect(settings.playbackRate == .normal)
        #expect(settings.loopPlayback == false)
        #expect(settings.autoPlay == false)
    }

    // MARK: - Immutable with* methods

    @Test("withTranscriptPosition returns new settings")
    func testWithTranscriptPosition() {
        let original = VideoPlayerSettings.default
        let updated = original.withTranscriptPosition(.left)

        #expect(updated.transcriptPosition == .left)
        #expect(original.transcriptPosition == .right)
        #expect(updated.playbackRate == original.playbackRate)
    }

    @Test("withTranscriptPanelSize returns new settings")
    func testWithTranscriptPanelSize() {
        let original = VideoPlayerSettings.default
        let updated = original.withTranscriptPanelSize(.wide)

        #expect(updated.transcriptPanelSize == .wide)
        #expect(original.transcriptPanelSize == .medium)
    }

    @Test("withTranscriptAutoScroll returns new settings")
    func testWithTranscriptAutoScroll() {
        let original = VideoPlayerSettings.default
        let updated = original.withTranscriptAutoScroll(false)

        #expect(updated.transcriptAutoScroll == false)
        #expect(original.transcriptAutoScroll == true)
    }

    @Test("withTranscriptVisibleByDefault returns new settings")
    func testWithTranscriptVisibleByDefault() {
        let original = VideoPlayerSettings.default
        let updated = original.withTranscriptVisibleByDefault(false)

        #expect(updated.transcriptVisibleByDefault == false)
        #expect(original.transcriptVisibleByDefault == true)
    }

    @Test("withTranscriptFontSize returns new settings")
    func testWithTranscriptFontSize() {
        let original = VideoPlayerSettings.default
        let updated = original.withTranscriptFontSize(.large)

        #expect(updated.transcriptFontSize == .large)
        #expect(original.transcriptFontSize == .medium)
    }

    @Test("withTranscriptShowTimestamps returns new settings")
    func testWithTranscriptShowTimestamps() {
        let original = VideoPlayerSettings.default
        let updated = original.withTranscriptShowTimestamps(false)

        #expect(updated.transcriptShowTimestamps == false)
        #expect(original.transcriptShowTimestamps == true)
    }

    @Test("withTimestampFormat returns new settings")
    func testWithTimestampFormat() {
        let original = VideoPlayerSettings.default
        let updated = original.withTimestampFormat(.hourMinuteSecond)

        #expect(updated.timestampFormat == .hourMinuteSecond)
        #expect(original.timestampFormat == .minuteSecond)
    }

    @Test("withPlaybackRate returns new settings")
    func testWithPlaybackRate() {
        let original = VideoPlayerSettings.default
        let updated = original.withPlaybackRate(.double)

        #expect(updated.playbackRate == .double)
        #expect(original.playbackRate == .normal)
    }

    @Test("withLoopPlayback returns new settings")
    func testWithLoopPlayback() {
        let original = VideoPlayerSettings.default
        let updated = original.withLoopPlayback(true)

        #expect(updated.loopPlayback == true)
        #expect(original.loopPlayback == false)
    }

    @Test("withAutoPlay returns new settings")
    func testWithAutoPlay() {
        let original = VideoPlayerSettings.default
        let updated = original.withAutoPlay(true)

        #expect(updated.autoPlay == true)
        #expect(original.autoPlay == false)
    }

    // MARK: - Codable round-trip

    @Test("Codable round-trip preserves all fields")
    func testCodableRoundTrip() throws {
        let settings = VideoPlayerSettings.default
            .withTranscriptPosition(.bottom)
            .withTranscriptPanelSize(.wide)
            .withTranscriptAutoScroll(false)
            .withTranscriptVisibleByDefault(false)
            .withTranscriptFontSize(.large)
            .withTranscriptShowTimestamps(false)
            .withTimestampFormat(.hourMinuteSecond)
            .withPlaybackRate(.oneAndHalf)
            .withLoopPlayback(true)
            .withAutoPlay(true)

        let data = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(VideoPlayerSettings.self, from: data)

        #expect(decoded == settings)
    }

    // MARK: - Enum values

    @Test("TranscriptPanelSize has correct side widths")
    func testPanelSizeWidths() {
        #expect(TranscriptPanelSize.narrow.sideWidth == 200)
        #expect(TranscriptPanelSize.medium.sideWidth == 280)
        #expect(TranscriptPanelSize.wide.sideWidth == 360)
    }

    @Test("TranscriptPanelSize has correct bottom heights")
    func testPanelSizeHeights() {
        #expect(TranscriptPanelSize.narrow.bottomHeight == 120)
        #expect(TranscriptPanelSize.medium.bottomHeight == 180)
        #expect(TranscriptPanelSize.wide.bottomHeight == 260)
    }

    @Test("TranscriptFontSize has correct text sizes")
    func testFontSizes() {
        #expect(TranscriptFontSize.small.textSize == 11)
        #expect(TranscriptFontSize.medium.textSize == 13)
        #expect(TranscriptFontSize.large.textSize == 15)
    }

    @Test("TimestampFormat formats m:ss correctly")
    func testTimestampFormatMinuteSecond() {
        let fmt = TimestampFormat.minuteSecond
        #expect(fmt.format(0) == "0:00")
        #expect(fmt.format(65) == "1:05")
        #expect(fmt.format(3661) == "61:01")
    }

    @Test("TimestampFormat formats h:mm:ss correctly")
    func testTimestampFormatHourMinuteSecond() {
        let fmt = TimestampFormat.hourMinuteSecond
        #expect(fmt.format(0) == "0:00:00")
        #expect(fmt.format(65) == "0:01:05")
        #expect(fmt.format(3661) == "1:01:01")
    }

    @Test("PlaybackRate has correct float values")
    func testPlaybackRates() {
        #expect(PlaybackRate.half.rate == 0.5)
        #expect(PlaybackRate.threeQuarters.rate == 0.75)
        #expect(PlaybackRate.normal.rate == 1.0)
        #expect(PlaybackRate.oneAndQuarter.rate == 1.25)
        #expect(PlaybackRate.oneAndHalf.rate == 1.5)
        #expect(PlaybackRate.double.rate == 2.0)
    }
}
