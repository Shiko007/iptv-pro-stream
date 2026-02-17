import Foundation
import os

@Observable
final class SearchViewModel {
    var searchText = "" {
        didSet { scheduleSearch() }
    }
    var results: [Channel] = []
    var isSearching = false

    private let dataManager = DataManager.shared
    private var searchTask: Task<Void, Never>?

    private func scheduleSearch() {
        searchTask?.cancel()
        guard !searchText.trimmed.isEmpty else {
            results = []
            return
        }

        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            await performSearch()
        }
    }

    private func performSearch() async {
        isSearching = true
        defer { isSearching = false }

        let query = searchText.trimmed.lowercased()
        do {
            let allChannels = try dataManager.fetchAllChannels()
            results = allChannels.filter { channel in
                channel.name.lowercased().contains(query) ||
                channel.groupTitle.lowercased().contains(query)
            }
        } catch {
            AppLogger.data.error("Search failed: \(error)")
        }
    }
}
