import Foundation
import os

@Observable
final class HomeViewModel {
    var recentlyWatched: [Channel] = []
    var favorites: [Channel] = []
    var isLoading = false

    private let dataManager = DataManager.shared

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            favorites = try dataManager.fetchFavorites()
            recentlyWatched = try dataManager.fetchRecentlyWatched(limit: 10).map { $0.channel }
        } catch {
            AppLogger.data.error("Failed to load home data: \(error)")
        }
    }
}
