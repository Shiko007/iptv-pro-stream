import SwiftUI

struct HomeView: View {
    @Bindable var viewModel: HomeViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if viewModel.recentlyWatched.isEmpty && viewModel.favorites.isEmpty {
                        ContentUnavailableView(
                            "Welcome to IPTV Pro Stream",
                            systemImage: "tv",
                            description: Text("Add a provider in Settings to get started.")
                        )
                    } else {
                        if !viewModel.recentlyWatched.isEmpty {
                            VStack(alignment: .leading) {
                                Text("Continue Watching")
                                    .font(.title2.bold())
                                    .padding(.horizontal)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    LazyHStack(spacing: 16) {
                                        ForEach(viewModel.recentlyWatched) { channel in
                                            NavigationLink {
                                                destinationView(for: channel)
                                            } label: {
                                                ChannelCardView(channel: channel)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }

                        if !viewModel.favorites.isEmpty {
                            VStack(alignment: .leading) {
                                Text("Favorites")
                                    .font(.title2.bold())
                                    .padding(.horizontal)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    LazyHStack(spacing: 16) {
                                        ForEach(viewModel.favorites) { channel in
                                            NavigationLink {
                                                destinationView(for: channel)
                                            } label: {
                                                ChannelCardView(channel: channel)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Home")
            .task {
                await viewModel.load()
            }
        }
    }

    @ViewBuilder
    private func destinationView(for channel: Channel) -> some View {
        VideoPlayerView(channel: channel)
    }
}
