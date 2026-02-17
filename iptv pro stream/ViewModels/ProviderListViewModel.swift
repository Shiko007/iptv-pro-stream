import Foundation
import os

@Observable
final class ProviderListViewModel {
    var providers: [Provider] = []
    var isLoading = false
    var isSyncing = false
    var syncingProviderID: UUID?
    var errorMessage: String?

    private let dataManager = DataManager.shared

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            providers = try dataManager.fetchProviders()
        } catch {
            errorMessage = error.localizedDescription
            AppLogger.data.error("Failed to load providers: \(error)")
        }
    }

    func addProvider(_ provider: Provider) async {
        do {
            try dataManager.saveProvider(provider)
            providers = try dataManager.fetchProviders()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteProvider(_ provider: Provider) async {
        do {
            try dataManager.deleteProvider(provider.id)
            providers = try dataManager.fetchProviders()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func syncProvider(_ provider: Provider) async {
        isSyncing = true
        syncingProviderID = provider.id
        defer {
            isSyncing = false
            syncingProviderID = nil
        }

        do {
            let updated = try await ProviderSyncService.shared.syncProvider(provider)
            try dataManager.saveProvider(updated)
            providers = try dataManager.fetchProviders()
            AppLogger.data.info("Provider \(provider.name) synced successfully")
        } catch {
            errorMessage = "Sync failed: \(error.localizedDescription)"
            AppLogger.network.error("Provider sync failed: \(error)")
        }
    }

    func syncAllProviders() async {
        for provider in providers {
            await syncProvider(provider)
        }
    }
}
