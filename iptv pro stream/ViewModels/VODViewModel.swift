import Foundation
import os

@Observable
final class VODViewModel {
    var items: [VODItem] = []
    var categories: [String] = []
    var selectedCategory: String? = nil
    var searchText = ""
    var isLoading = false
    var errorMessage: String?

    private let dataManager = DataManager.shared
    private var contentType: VODContentType = .movie
    private var hasLoaded = false

    var filteredItems: [VODItem] {
        var result = items

        if let category = selectedCategory {
            result = result.filter { $0.categoryID == category }
        }

        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }

        return result
    }

    var shelves: [HomeGenreShelf] {
        var grouped: [String: [VODItem]] = [:]
        for item in filteredItems {
            grouped[item.categoryID, default: []].append(item)
        }
        return grouped
            .map { HomeGenreShelf(title: $0.key, items: $0.value) }
            .sorted { $0.items.count > $1.items.count }
    }

    func load(type: VODContentType) async {
        contentType = type
        guard !hasLoaded else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let streamType: StreamType = type == .movie ? .movie : .series
            let channels = try dataManager.fetchAllChannels(streamType: streamType)

            items = channels.map { channel in
                VODItem(
                    id: channel.id,
                    name: channel.name,
                    streamURL: channel.streamURL,
                    logoURL: channel.logoURL,
                    plot: channel.plot,
                    cast: channel.cast,
                    director: channel.director,
                    genre: channel.genre,
                    releaseDate: channel.releaseDate,
                    duration: channel.duration,
                    rating: channel.rating,
                    categoryID: channel.groupTitle,
                    containerExtension: channel.containerExtension,
                    providerID: channel.providerID,
                    streamType: channel.streamType,
                    seriesID: channel.streamID
                )
            }

            categories = Array(Set(items.map { $0.categoryID })).sorted()
            hasLoaded = true
        } catch {
            errorMessage = error.localizedDescription
            AppLogger.data.error("Failed to load VOD items: \(error)")
        }
    }

    func reload() async {
        hasLoaded = false
        await load(type: contentType)
    }
}
