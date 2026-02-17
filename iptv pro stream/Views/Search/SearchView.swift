import SwiftUI

struct SearchView: View {
    @State private var viewModel = SearchViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.searchText.isEmpty {
                    ContentUnavailableView(
                        "Search",
                        systemImage: "magnifyingglass",
                        description: Text("Search across all channels, movies, and series.")
                    )
                } else if viewModel.results.isEmpty && !viewModel.isSearching {
                    ContentUnavailableView.search(text: viewModel.searchText)
                } else {
                    List(viewModel.results) { channel in
                        NavigationLink(value: channel) {
                            ChannelRowView(channel: channel)
                        }
                    }
                    .navigationDestination(for: Channel.self) { channel in
                        VideoPlayerView(channel: channel)
                    }
                }
            }
            .navigationTitle("Search")
            .searchable(text: $viewModel.searchText, prompt: "Channels, movies, series...")
        }
    }
}
