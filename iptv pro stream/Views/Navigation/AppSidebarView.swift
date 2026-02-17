import SwiftUI

struct AppSidebarView: View {
    @State private var selectedTab: AppTab? = .home
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic
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
                        .tag(AppTab.search) // Reuse for now
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
                HomeView()
            case .liveTV:
                LiveTVView()
            case .movies:
                VODBrowserView(contentType: .movie)
            case .series:
                VODBrowserView(contentType: .series)
            case .search:
                SearchView()
            case .settings:
                SettingsView()
            case .none:
                HomeView()
            }
        }
        #if os(macOS)
        .onChange(of: fullScreenController.isFullScreen) { _, isFullScreen in
            withAnimation {
                columnVisibility = isFullScreen ? .detailOnly : .automatic
            }
        }
        #endif
    }
}
