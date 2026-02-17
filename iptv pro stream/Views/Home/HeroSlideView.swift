import SwiftUI

struct HeroSlideView: View {
    let item: VODItem

    var body: some View {
        NavigationLink {
            destinationView
        } label: {
            ZStack(alignment: .bottomLeading) {
                AsyncCachedImage(url: item.logoURL) {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.2))
                        .overlay {
                            Image(systemName: "film")
                                .font(.system(size: 48))
                                .foregroundStyle(.secondary)
                        }
                }
                .aspectRatio(16/9, contentMode: .fill)
                .clipped()

                // Gradient scrim
                LinearGradient(
                    colors: [.clear, .black.opacity(0.8)],
                    startPoint: .center,
                    endPoint: .bottom
                )

                // Text overlay
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.name)
                        .font(.title2.bold())
                        .lineLimit(2)

                    HStack(spacing: 10) {
                        if let genre = item.genre, !genre.isEmpty {
                            Text(genre.components(separatedBy: ",").first ?? genre)
                                .font(.caption.weight(.medium))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(.ultraThinMaterial, in: Capsule())
                        }

                        if let rating = item.rating, !rating.isEmpty {
                            Label(rating, systemImage: "star.fill")
                                .font(.caption)
                        }
                    }

                    if let plot = item.plot, !plot.isEmpty {
                        Text(plot)
                            .font(.caption)
                            .lineLimit(2)
                            .opacity(0.9)
                    }
                }
                .foregroundStyle(.white)
                .padding()
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var destinationView: some View {
        switch item.streamType {
        case .series:
            SeriesDetailView(item: item)
        case .movie:
            VODDetailView(item: item)
        case .live:
            VideoPlayerView(channel: item.toChannel())
        }
    }
}
