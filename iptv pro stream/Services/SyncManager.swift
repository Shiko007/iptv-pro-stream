import Foundation
import os

@Observable
final class SyncManager {
    static let shared = SyncManager()

    static let didFinishSyncing = Notification.Name("SyncManager.didFinishSyncing")

    var isSyncing = false
    var syncMessage: String?

    private let dataManager = DataManager.shared

    func syncAllProviders() async {
        isSyncing = true
        syncMessage = "Syncing providers..."

        do {
            let providers = try dataManager.fetchProviders()
            for (index, provider) in providers.enumerated() {
                syncMessage = "Syncing \(provider.name) (\(index + 1)/\(providers.count))..."
                do {
                    let updated = try await ProviderSyncService.shared.syncProvider(provider)
                    try await MainActor.run {
                        try dataManager.saveProvider(updated)
                    }
                    AppLogger.data.info("Provider \(provider.name) synced successfully")
                } catch {
                    AppLogger.network.error("Failed to sync \(provider.name): \(error)")
                }
            }
        } catch {
            AppLogger.data.error("Failed to fetch providers for sync: \(error)")
        }

        isSyncing = false
        syncMessage = nil
        NotificationCenter.default.post(name: Self.didFinishSyncing, object: nil)
    }
}
