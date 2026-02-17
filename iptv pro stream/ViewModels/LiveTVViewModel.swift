import Foundation
import os

nonisolated struct ChannelShelf: Identifiable, Sendable {
    var id: String { title }
    var title: String
    var channels: [Channel]
}

@Observable
final class LiveTVViewModel {
    var channels: [Channel] = []
    var categories: [String] = []
    var selectedCategory: String? = nil
    var searchText = ""
    var isLoading = false
    var errorMessage: String?

    private let dataManager = DataManager.shared
    private var hasLoaded = false

    var filteredChannels: [Channel] {
        var result = channels

        if let category = selectedCategory {
            result = result.filter { $0.groupTitle == category }
        }

        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }

        return result
    }

    var shelves: [ChannelShelf] {
        var grouped: [String: [Channel]] = [:]
        for channel in filteredChannels {
            grouped[channel.groupTitle, default: []].append(channel)
        }
        return grouped
            .map { ChannelShelf(title: $0.key, channels: $0.value) }
            .sorted { $0.channels.count > $1.channels.count }
    }

    func load() async {
        guard !hasLoaded else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            channels = try dataManager.fetchAllChannels(streamType: .live)
            categories = Array(Set(channels.map { $0.groupTitle })).sorted()
            hasLoaded = true
        } catch {
            errorMessage = error.localizedDescription
            AppLogger.data.error("Failed to load channels: \(error)")
        }
    }

    func reload() async {
        hasLoaded = false
        await load()
    }
}
