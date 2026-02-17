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
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 16)], spacing: 16) {
                            ForEach(viewModel.filteredItems) { item in
                                NavigationLink {
                                    if item.streamType == .series {
                                        SeriesDetailView(item: item)
                                    } else {
                                        VODDetailView(item: item)
                                    }
                                } label: {
                                    VODCardView(item: item)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(contentType == .movie ? "Movies" : "Series")
            #if os(iOS)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !viewModel.categories.isEmpty {
                        Menu {
                            Button("All") {
                                viewModel.selectedCategory = nil
                            }
                            ForEach(viewModel.categories, id: \.self) { category in
                                Button(category) {
                                    viewModel.selectedCategory = category
                                }
                            }
                        } label: {
                            Label(
                                viewModel.selectedCategory ?? "All Categories",
                                systemImage: "line.3.horizontal.decrease.circle"
                            )
                        }
                    }
                }
            }
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
        }
    }
}
