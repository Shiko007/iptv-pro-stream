import Foundation
import os

nonisolated struct HomeGenreShelf: Identifiable, Sendable {
    var id: String { title }
    var title: String
    var items: [VODItem]
}

@Observable
final class HomeViewModel {
    var continueWatching: [Channel] = []
    var watchProgress: [String: Double] = [:]
    var favorites: [Channel] = []
    var heroItems: [VODItem] = []
    var movieShelves: [HomeGenreShelf] = []
    var seriesShelves: [HomeGenreShelf] = []
    var isLoading = false

    private let dataManager = DataManager.shared
    private var hasLoaded = false

    func load() async {
        guard !hasLoaded else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            favorites = try dataManager.fetchFavorites()
            loadRecentlyWatched()

            let movies = try dataManager.fetchAllChannels(streamType: .movie).map { $0.toVODItem() }
            let series = try dataManager.fetchAllChannels(streamType: .series).map { $0.toVODItem() }

            // Hero: top 8 items that have poster art and a plot
            let heroPool = (movies + series)
                .filter { $0.logoURL != nil && $0.plot != nil && !($0.plot?.isEmpty ?? true) }
            heroItems = Array(heroPool.prefix(8))

            // Group movies by category into shelves (min 4 items)
            movieShelves = buildShelves(from: movies)
            seriesShelves = buildShelves(from: series)

            hasLoaded = true
        } catch {
            AppLogger.data.error("Failed to load home data: \(error)")
        }
    }

    func refreshDynamicShelves() {
        do {
            loadRecentlyWatched()
            favorites = try dataManager.fetchFavorites()
        } catch {
            AppLogger.data.error("Failed to refresh dynamic shelves: \(error)")
        }
    }

    private func loadRecentlyWatched() {
        guard let entries = try? dataManager.fetchRecentlyWatched(limit: 10) else { return }
        continueWatching = entries.map { $0.channel }
        watchProgress = Dictionary(uniqueKeysWithValues: entries.compactMap { entry in
            guard entry.duration > 0 else { return nil }
            return (entry.channel.id, entry.position / entry.duration)
        })
    }

    func removeFromContinueWatching(_ channel: Channel) {
        try? dataManager.removeRecentlyWatched(channel.id)
        continueWatching.removeAll { $0.id == channel.id }
        watchProgress.removeValue(forKey: channel.id)
    }

    func refresh() async {
        hasLoaded = false
        await load()
    }

    private func buildShelves(from items: [VODItem]) -> [HomeGenreShelf] {
        var grouped: [String: [VODItem]] = [:]
        for item in items {
            grouped[item.categoryID, default: []].append(item)
        }
        return grouped
            .filter { $0.value.count >= 4 }
            .map { HomeGenreShelf(title: $0.key, items: $0.value) }
            .sorted { $0.items.count > $1.items.count }
    }
}
