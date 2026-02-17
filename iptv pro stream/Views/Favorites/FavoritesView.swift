import SwiftUI

struct FavoritesView: View {
    @State private var viewModel = FavoritesViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.favorites.isEmpty {
                    ContentUnavailableView(
                        "No Favorites",
                        systemImage: "heart.slash",
                        description: Text("Tap the heart icon on a channel to add it to favorites.")
                    )
                } else {
                    List(viewModel.favorites) { channel in
                        NavigationLink(value: channel) {
                            ChannelRowView(channel: channel)
                        }
                    }
                    .navigationDestination(for: Channel.self) { channel in
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
            }
            .navigationTitle("Favorites")
            .task {
                await viewModel.load()
            }
        }
    }
}
