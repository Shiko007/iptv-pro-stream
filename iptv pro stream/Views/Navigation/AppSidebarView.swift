import SwiftUI

struct AppSidebarView: View {
    @State private var selectedTab: AppTab? = .home
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic
    @State private var homeViewModel = HomeViewModel()
    @State private var liveTVViewModel = LiveTVViewModel()
    @State private var moviesViewModel = VODViewModel()
    @State private var seriesViewModel = VODViewModel()
    @State private var searchViewModel = SearchViewModel()
    private var syncManager = SyncManager.shared
    #if os(macOS)
    private var fullScreenController = FullScreenPlayerController.shared
    #endif

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            List(selection: $selectedTab) {
                Label("Home", systemImage: "house.fill")
                    .tag(AppTab.home)
                Label("Live TV", systemImage: "tv.fill")
                    .tag(AppTab.liveTV)
                Label("Movies", systemImage: "film.fill")
                    .tag(AppTab.movies)
                Label("Series", systemImage: "play.rectangle.on.rectangle.fill")
                    .tag(AppTab.series)

                Section("Library") {
                    Label("Favorites", systemImage: "heart.fill")
                        .tag(AppTab.favorites)
                    Label("Search", systemImage: "magnifyingglass")
                        .tag(AppTab.search)
                }

                Section {
                    Label("Settings", systemImage: "gearshape.fill")
                        .tag(AppTab.settings)
                }
            }
            .navigationTitle(Constants.App.name)
            .safeAreaInset(edge: .bottom) {
                if syncManager.isSyncing {
                    SyncingBannerView(message: syncManager.syncMessage)
                        .padding(.bottom, 8)
                }
            }
        } detail: {
            switch selectedTab {
            case .home:
                HomeView(viewModel: homeViewModel)
            case .liveTV:
                LiveTVView(viewModel: liveTVViewModel)
            case .movies:
                VODBrowserView(contentType: .movie, viewModel: moviesViewModel)
            case .series:
                VODBrowserView(contentType: .series, viewModel: seriesViewModel)
            case .favorites:
                FavoritesView()
            case .search:
                SearchView(viewModel: searchViewModel)
            case .settings:
                SettingsView()
            case .none:
                HomeView(viewModel: homeViewModel)
            }
        }
        #if os(macOS)
        .onChange(of: fullScreenController.isFullScreen) { _, isFullScreen in
            withAnimation {
                columnVisibility = (isFullScreen || fullScreenController.isVideoPlaying) ? .detailOnly : .automatic
            }
        }
        .onChange(of: fullScreenController.isVideoPlaying) { _, isVideoPlaying in
            withAnimation {
                columnVisibility = (isVideoPlaying || fullScreenController.isFullScreen) ? .detailOnly : .automatic
            }
        }
        #endif
    }
}
