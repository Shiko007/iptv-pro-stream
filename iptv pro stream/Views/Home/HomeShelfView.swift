import SwiftUI

// MARK: - VOD Shelf (poster cards for movies/series)

struct HomeVODShelfView: View {
    let title: String
    let items: [VODItem]

    #if os(tvOS)
    private let cardWidth: CGFloat = 200
    #else
    private let cardWidth: CGFloat = 130
    #endif

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title3.bold())
                .padding(.horizontal, Constants.UI.defaultPadding)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(items) { item in
                        NavigationLink(value: item) {
                            VODCardView(item: item)
                                .frame(width: cardWidth)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Constants.UI.defaultPadding)
            }
        }
    }
}

// MARK: - Channel Shelf (continue watching / favorites — mixed types)

struct HomeChannelShelfView: View {
    let title: String
    let channels: [Channel]
    var watchProgress: [String: Double] = [:]
    var onContinueWatching: ((Channel) -> Void)?

    #if os(tvOS)
    private let cardWidth: CGFloat = 200
    #else
    private let cardWidth: CGFloat = 130
    #endif

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title3.bold())
                .padding(.horizontal, Constants.UI.defaultPadding)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(channels) { channel in
                        if let onContinueWatching {
                            Button {
                                onContinueWatching(channel)
                            } label: {
                                cardView(for: channel)
                            }
                            .buttonStyle(.plain)
                        } else {
                            NavigationLink {
                                destinationView(for: channel)
                            } label: {
                                cardView(for: channel)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, Constants.UI.defaultPadding)
            }
        }
    }

    @ViewBuilder
    private func cardView(for channel: Channel) -> some View {
        let progress = watchProgress[channel.id]
        switch channel.streamType {
        case .movie, .series:
            VODCardView(item: channel.toVODItem(), progress: progress)
                .frame(width: cardWidth)
        case .live:
            ChannelCardView(channel: channel, progress: progress)
                .frame(width: cardWidth)
        }
    }

    @ViewBuilder
    private func destinationView(for channel: Channel) -> some View {
        switch channel.streamType {
        case .series:
            SeriesDetailView(item: channel.toVODItem())
        case .movie:
            VODDetailView(item: channel.toVODItem())
        case .live:
            VideoPlayerView(channel: channel)
        }
    }
}
