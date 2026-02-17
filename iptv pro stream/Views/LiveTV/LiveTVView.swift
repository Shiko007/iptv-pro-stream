import SwiftUI

struct LiveTVView: View {
    @Bindable var viewModel: LiveTVViewModel

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
                } else if viewModel.shelves.isEmpty {
                    ContentUnavailableView.search
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 24) {
                            ForEach(viewModel.shelves) { shelf in
                                HomeChannelShelfView(
                                    title: shelf.title,
                                    channels: shelf.channels
                                )
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Live TV")
            #if os(macOS)
            .toolbarBackground(.hidden, for: .windowToolbar)
            #else
            .toolbarBackground(.hidden, for: .navigationBar)
            #endif
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
