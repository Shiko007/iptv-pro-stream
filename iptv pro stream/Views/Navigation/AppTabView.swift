import SwiftUI

struct AppTabView: View {
    @State private var selectedTab: AppTab = .home
    @State private var homeViewModel = HomeViewModel()
    @State private var liveTVViewModel = LiveTVViewModel()
    @State private var moviesViewModel = VODViewModel()
    @State private var seriesViewModel = VODViewModel()
    @State private var searchViewModel = SearchViewModel()
    private var syncManager = SyncManager.shared

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(viewModel: homeViewModel)
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(AppTab.home)

            LiveTVView(viewModel: liveTVViewModel)
                .tabItem { Label("Live TV", systemImage: "tv.fill") }
                .tag(AppTab.liveTV)

            VODBrowserView(contentType: .movie, viewModel: moviesViewModel)
                .tabItem { Label("Movies", systemImage: "film.fill") }
                .tag(AppTab.movies)

            VODBrowserView(contentType: .series, viewModel: seriesViewModel)
                .tabItem { Label("Series", systemImage: "play.rectangle.on.rectangle.fill") }
                .tag(AppTab.series)

            SearchView(viewModel: searchViewModel)
                .tabItem { Label("Search", systemImage: "magnifyingglass") }
                .tag(AppTab.search)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(AppTab.settings)
        }
        .overlay(alignment: .top) {
            if syncManager.isSyncing {
                SyncingBannerView(message: syncManager.syncMessage)
            }
        }
    }
}

enum AppTab: Hashable {
    case home, liveTV, movies, series, favorites, search, settings
}

struct SyncingBannerView: View {
    let message: String?

    var body: some View {
        HStack(spacing: 8) {
            ProgressView()
                #if os(macOS)
                .controlSize(.small)
                #endif
            Text(message ?? "Syncing...")
                .font(.subheadline)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .padding(.top, 8)
    }
}
