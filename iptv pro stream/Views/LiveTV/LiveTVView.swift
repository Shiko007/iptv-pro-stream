import SwiftUI

struct LiveTVView: View {
    @State private var viewModel = LiveTVViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading channels...")
                } else if viewModel.channels.isEmpty {
                    ContentUnavailableView(
                        "No Channels",
                        systemImage: "tv.slash",
                        description: Text("Add a provider to view live TV channels.")
                    )
                } else {
                    ChannelListView(
                        channels: viewModel.filteredChannels,
                        categories: viewModel.categories,
                        selectedCategory: $viewModel.selectedCategory
                    )
                }
            }
            .navigationTitle("Live TV")
            .task {
                await viewModel.load()
            }
            .onReceive(NotificationCenter.default.publisher(for: SyncManager.didFinishSyncing)) { _ in
                Task {
                    await viewModel.reload()
                }
            }
            .searchable(text: $viewModel.searchText, prompt: "Search channels")
        }
    }
}
