import SwiftUI
import SwiftData

@main
struct iptv_pro_streamApp: App {
    let dataManager = DataManager.shared

    var body: some Scene {
        WindowGroup {
            RootNavigationView()
        }
        .modelContainer(dataManager.modelContainer)
    }
}
