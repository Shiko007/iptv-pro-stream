import SwiftUI

struct RootNavigationView: View {
    @State private var hasProviders = false
    @State private var hasChecked = false
    private let dataManager = DataManager.shared

    var body: some View {
        Group {
            if !hasChecked {
                ProgressView()
            } else if !hasProviders {
                NavigationStack {
                    ProviderListView(onProviderAdded: {
                        hasProviders = true
                        Task {
                            await SyncManager.shared.syncAllProviders()
                        }
                    })
                }
            } else {
                #if os(macOS)
                AppSidebarView()
                #else
                AppTabView()
                #endif
            }
        }
        .task {
            checkProviders()
        }
    }

    private func checkProviders() {
        do {
            let providers = try dataManager.fetchProviders()
            hasProviders = !providers.isEmpty
        } catch {
            hasProviders = false
        }
        hasChecked = true
    }
}
