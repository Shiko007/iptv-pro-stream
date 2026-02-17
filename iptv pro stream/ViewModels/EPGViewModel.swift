import Foundation
import os

@Observable
final class EPGViewModel {
    var programmes: [String: [EPGProgramme]] = [:]
    var channelIDs: [String] = []
    var isLoading = false

    private let dataManager = DataManager.shared

    func load() async {
        isLoading = true
        isLoading = false
    }

    func programmes(for channelID: String) -> [EPGProgramme] {
        programmes[channelID] ?? []
    }

    func channelName(for channelID: String) -> String {
        channelID
    }

    func nowPlaying(for channelID: String) -> EPGProgramme? {
        programmes(for: channelID).first { $0.isCurrentlyAiring }
    }

    func nextProgramme(for channelID: String) -> EPGProgramme? {
        let progs = programmes(for: channelID)
        guard let nowIndex = progs.firstIndex(where: { $0.isCurrentlyAiring }) else { return progs.first }
        let nextIndex = progs.index(after: nowIndex)
        return nextIndex < progs.endIndex ? progs[nextIndex] : nil
    }
}
