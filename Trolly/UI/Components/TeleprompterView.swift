import SwiftUI

struct TeleprompterView: View {
    let script: Script
    let settings: TeleprompterSettings
    let isRecording: Bool

    @State private var scrollOffset: CGFloat = 0
    @State private var isScrolling: Bool = false
    @State private var contentHeight: CGFloat = 0
    @State private var viewHeight: CGFloat = 0
    @State private var scrollTimer: Timer?

    var body: some View {
        ZStack {
            backgroundColor
            scrollContent
            controlsOverlay
        }
        .onChange(of: isRecording) { _, recording in
            if recording {
                startScrolling()
            } else {
                stopScrolling()
            }
        }
        .onDisappear {
            stopScrolling()
        }
    }

    // MARK: - Background

    private var backgroundColor: some View {
        Rectangle()
            .fill(settings.backgroundColor.swiftUIColor.opacity(settings.backgroundOpacity))
    }

    // MARK: - Scroll Content

    private var scrollContent: some View {
        GeometryReader { geometry in
            let topPadding = geometry.size.height * 0.4
            let bottomPadding = geometry.size.height * 0.6

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer().frame(height: topPadding)

                    Text(script.content)
                        .font(.system(size: settings.fontSize.points, weight: .medium))
                        .foregroundStyle(settings.textColor.swiftUIColor)
                        .lineSpacing(settings.fontSize.points * 0.5)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .background(
                            GeometryReader { contentGeo in
                                Color.clear.preference(
                                    key: ContentHeightKey.self,
                                    value: contentGeo.size.height
                                )
                            }
                        )

                    Spacer().frame(height: bottomPadding)
                }
                .frame(maxWidth: .infinity)
                .offset(y: -scrollOffset)
            }
            .scrollDisabled(true)
            .scaleEffect(x: settings.mirrorHorizontally ? -1 : 1, y: 1)
            .onPreferenceChange(ContentHeightKey.self) { height in
                contentHeight = height
            }
            .onAppear {
                viewHeight = geometry.size.height
            }
            .onChange(of: geometry.size.height) { _, newHeight in
                viewHeight = newHeight
            }
        }
        .overlay(readingGuide)
    }

    // MARK: - Reading Guide

    private var readingGuide: some View {
        VStack {
            Spacer()
                .frame(maxHeight: .infinity)
            Rectangle()
                .fill(settings.textColor.swiftUIColor.opacity(0.3))
                .frame(height: 2)
            Spacer()
                .frame(maxHeight: .infinity)
        }
    }

    // MARK: - Controls

    private var controlsOverlay: some View {
        VStack {
            Spacer()
            HStack(spacing: 16) {
                Button {
                    toggleScrolling()
                } label: {
                    Image(systemName: isScrolling ? "pause.fill" : "play.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(.white.opacity(0.2), in: Circle())
                }
                .buttonStyle(.plain)
                .help(isScrolling ? "Pause scrolling" : "Resume scrolling")

                Button {
                    resetScroll()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 12))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(.white.opacity(0.2), in: Circle())
                }
                .buttonStyle(.plain)
                .help("Reset to start")

                Text(settings.scrollSpeed.label)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(8)
        }
    }

    // MARK: - Scrolling

    private func startScrolling() {
        isScrolling = true
        let interval: TimeInterval = 1.0 / 30.0
        let increment = settings.scrollSpeed.pointsPerSecond * interval
        scrollTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            DispatchQueue.main.async {
                let maxOffset = contentHeight
                if scrollOffset < maxOffset {
                    scrollOffset += increment
                } else {
                    stopScrolling()
                }
            }
        }
    }

    private func stopScrolling() {
        isScrolling = false
        scrollTimer?.invalidate()
        scrollTimer = nil
    }

    private func toggleScrolling() {
        if isScrolling {
            stopScrolling()
        } else {
            startScrolling()
        }
    }

    private func resetScroll() {
        stopScrolling()
        scrollOffset = 0
    }
}

// MARK: - Preference Key

private struct ContentHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Color Extension

extension TeleprompterColor {
    var swiftUIColor: Color {
        switch self {
        case .white: return .white
        case .black: return .black
        case .green: return .green
        case .yellow: return .yellow
        }
    }
}
