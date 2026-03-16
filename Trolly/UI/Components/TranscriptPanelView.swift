import SwiftUI

struct TranscriptPanelView: View {
    let transcript: Transcript
    let currentTime: TimeInterval
    let settings: VideoPlayerSettings

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: segmentSpacing) {
                    ForEach(Array(transcript.segments.enumerated()), id: \.offset) { index, segment in
                        TranscriptSegmentRow(
                            segment: segment,
                            isActive: isSegmentActive(segment),
                            settings: settings
                        )
                        .id(index)
                    }
                }
                .padding(12)
            }
            .onChange(of: currentTime) { _, newTime in
                guard settings.transcriptAutoScroll else { return }
                if let activeIndex = activeSegmentIndex(at: newTime) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        proxy.scrollTo(activeIndex, anchor: .center)
                    }
                }
            }
        }
    }

    private var segmentSpacing: CGFloat {
        switch settings.transcriptFontSize {
        case .small: return 4
        case .medium: return 6
        case .large: return 8
        }
    }

    private func isSegmentActive(_ segment: TranscriptSegment) -> Bool {
        currentTime >= segment.start && currentTime < segment.end
    }

    private func activeSegmentIndex(at time: TimeInterval) -> Int? {
        transcript.segments.firstIndex { time >= $0.start && time < $0.end }
    }
}

struct TranscriptSegmentRow: View {
    let segment: TranscriptSegment
    let isActive: Bool
    let settings: VideoPlayerSettings

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if settings.transcriptShowTimestamps {
                Text(settings.timestampFormat.format(segment.start))
                    .font(.system(size: settings.transcriptFontSize.timestampSize, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .frame(width: timestampWidth, alignment: .trailing)
            }

            Text(segment.text)
                .font(.system(size: settings.transcriptFontSize.textSize))
                .foregroundStyle(isActive ? .primary : .secondary)
                .fontWeight(isActive ? .medium : .regular)
        }
        .padding(.vertical, 3)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(isActive ? Color.accentColor.opacity(0.1) : .clear)
        )
    }

    private var timestampWidth: CGFloat {
        switch settings.timestampFormat {
        case .minuteSecond: return 40
        case .hourMinuteSecond: return 56
        }
    }
}
