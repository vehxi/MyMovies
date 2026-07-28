import AppKit
import SwiftUI

struct PosterArtwork: View {
    let title: String
    let filename: String?

    @State private var image: NSImage?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.quaternary)

            if let image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .accessibilityLabel(Text("Cover for \(title)"))
            } else {
                placeholder
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(.primary.opacity(0.08))
        }
        .task(id: filename) {
            await loadImage()
        }
    }

    private var placeholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "film")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(.tertiary)
            Text(title.isEmpty ? String(localized: "Untitled Movie") : title)
                .font(.headline)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 14)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("No cover. \(title)"))
    }

    @MainActor
    private func loadImage() async {
        guard let filename,
              let url = await CoverStore.shared.url(for: filename)
        else {
            image = nil
            return
        }
        image = NSImage(contentsOf: url)
    }
}
