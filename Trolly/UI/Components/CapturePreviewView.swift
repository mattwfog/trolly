import SwiftUI
import AppKit

struct CapturePreviewView: View {
    let previewImage: NSImage?
    let isLoading: Bool
    let sourceName: String
    let aspectRatio: CGFloat

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            previewContent
            sourceNameLabel
        }
        .frame(height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.quaternary, lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var previewContent: some View {
        if let image = previewImage {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: 180)
                .background(Color.black)
        } else {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .controlBackgroundColor))
                .overlay {
                    if isLoading {
                        VStack(spacing: 8) {
                            ProgressView()
                                .controlSize(.small)
                            Text("Connecting...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
        }
    }

    private var sourceNameLabel: some View {
        Text(sourceName)
            .font(.caption2)
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(.black.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .padding(6)
    }
}

#Preview("Loading") {
    CapturePreviewView(
        previewImage: nil,
        isLoading: true,
        sourceName: "Built-in Display",
        aspectRatio: 16.0 / 9.0
    )
    .frame(width: 420)
}
