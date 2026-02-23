import SwiftUI

enum VODContentType {
    case movie, series
}

struct VODBrowserView: View {
    let contentType: VODContentType
    @Bindable var viewModel: VODViewModel

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.items.isEmpty {
                    ProgressView("Loading...")
                } else if viewModel.items.isEmpty {
                    ContentUnavailableView(
                        contentType == .movie ? "No Movies" : "No Series",
                        systemImage: "film.stack",
                        description: Text("Add a provider with VOD content to browse.")
                    )
                } else if viewModel.shelves.isEmpty {
                    ContentUnavailableView.search
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 24) {
                            ForEach(viewModel.shelves) { shelf in
                                HomeVODShelfView(
                                    title: shelf.title,
                                    items: shelf.items,
                                    watchProgress: viewModel.watchProgress
                                )
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle(contentType == .movie ? "Movies" : "Series")
            #if os(macOS)
            .toolbarBackground(.hidden, for: .windowToolbar)
            #else
            .toolbarBackground(.hidden, for: .navigationBar)
            #endif
            .searchable(text: $viewModel.searchText, prompt: "Search \(contentType == .movie ? "movies" : "series")")
            .task {
                await viewModel.load(type: contentType)
            }
            .onReceive(NotificationCenter.default.publisher(for: SyncManager.didFinishSyncing)) { _ in
                Task {
                    await viewModel.reload()
                }
            }
            .onAppear {
                viewModel.refreshProgress()
            }
            .onReceive(NotificationCenter.default.publisher(for: PlayerViewModel.didStopPlayback)) { _ in
                viewModel.refreshProgress()
            }
            .navigationDestination(for: VODItem.self) { item in
                if item.streamType == .series {
                    SeriesDetailView(item: item)
                } else {
                    VODDetailView(item: item)
                }
            }
        }
    }
}
