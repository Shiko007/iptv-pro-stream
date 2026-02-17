import SwiftUI

struct HomeView: View {
    @Bindable var viewModel: HomeViewModel
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading...")
                } else if isEmpty {
                    ContentUnavailableView(
                        "Welcome to IPTV Pro Stream",
                        systemImage: "tv",
                        description: Text("Add a provider in Settings to get started.")
                    )
                } else {
                    contentView
                }
            }
            .navigationTitle("Home")
            #if os(macOS)
            .toolbarBackground(.hidden, for: .windowToolbar)
            #else
            .toolbarBackground(.hidden, for: .navigationBar)
            #endif
            .task {
                await viewModel.load()
            }
            .onAppear {
                viewModel.refreshDynamicShelves()
            }
            .onReceive(NotificationCenter.default.publisher(for: SyncManager.didFinishSyncing)) { _ in
                Task { await viewModel.refresh() }
            }
            .navigationDestination(for: VODItem.self) { item in
                if item.streamType == .series {
                    SeriesDetailView(item: item)
                } else {
                    VODDetailView(item: item)
                }
            }
            .navigationDestination(for: Channel.self) { channel in
                VideoPlayerView(channel: channel)
            }
        }
    }

    private var isEmpty: Bool {
        viewModel.continueWatching.isEmpty
        && viewModel.favorites.isEmpty
        && viewModel.movieShelves.isEmpty
        && viewModel.seriesShelves.isEmpty
    }

    private func handleContinueWatching(_ channel: Channel) {
        let item = channel.toVODItem()
        navigationPath.append(item)
        navigationPath.append(channel)
    }

    private var contentView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                // Continue Watching
                if !viewModel.continueWatching.isEmpty {
                    HomeChannelShelfView(
                        title: "Continue Watching",
                        channels: viewModel.continueWatching,
                        watchProgress: viewModel.watchProgress,
                        onContinueWatching: handleContinueWatching,
                        onRemove: { viewModel.removeFromContinueWatching($0) }
                    )
                }

                // Favorites
                if !viewModel.favorites.isEmpty {
                    HomeChannelShelfView(
                        title: "Favorites",
                        channels: viewModel.favorites
                    )
                }

                // Movie shelves
                ForEach(viewModel.movieShelves) { shelf in
                    HomeVODShelfView(title: shelf.title, items: shelf.items)
                }

                // Series shelves
                if !viewModel.seriesShelves.isEmpty {
                    Text("Series")
                        .font(.title2.bold())
                        .padding(.horizontal, Constants.UI.defaultPadding)
                        .padding(.top, 8)

                    ForEach(viewModel.seriesShelves) { shelf in
                        HomeVODShelfView(title: shelf.title, items: shelf.items)
                    }
                }
            }
            .padding(.vertical)
        }
    }
}
