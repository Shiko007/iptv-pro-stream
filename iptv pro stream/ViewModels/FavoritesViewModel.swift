import Foundation
import os

@Observable
final class FavoritesViewModel {
    var favorites: [Channel] = []
    var isLoading = false

    private let dataManager = DataManager.shared

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            favorites = try dataManager.fetchFavorites()
        } catch {
            AppLogger.data.error("Failed to load favorites: \(error)")
        }
    }

    func toggleFavorite(_ channel: Channel) async {
        do {
            try dataManager.toggleFavorite(channel)
            favorites = try dataManager.fetchFavorites()
        } catch {
            AppLogger.data.error("Failed to toggle favorite: \(error)")
        }
    }
}
