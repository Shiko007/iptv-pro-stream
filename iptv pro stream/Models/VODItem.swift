import Foundation

nonisolated struct VODItem: Identifiable, Codable, Sendable, Hashable {
    var id: String
    var name: String
    var streamURL: String
    var logoURL: String?
    var plot: String?
    var cast: String?
    var director: String?
    var genre: String?
    var releaseDate: String?
    var duration: String?
    var rating: String?
    var categoryID: String
    var containerExtension: String?
    var providerID: UUID
    var streamType: StreamType

    func toChannel() -> Channel {
        Channel(
            id: id,
            name: name,
            logoURL: logoURL,
            groupTitle: categoryID,
            streamURL: streamURL,
            streamType: streamType,
            providerID: providerID
        )
    }

    // Series-specific
    var seriesID: Int?
    var seasonNumber: Int?
    var episodeNumber: Int?
    var seasons: [Season]?
}

nonisolated struct Season: Identifiable, Codable, Sendable, Hashable {
    var id: Int
    var name: String
    var seasonNumber: Int
    var episodes: [Episode]
    var coverURL: String?
}

nonisolated struct Episode: Identifiable, Codable, Sendable, Hashable {
    var id: String
    var title: String
    var episodeNumber: Int
    var seasonNumber: Int
    var streamURL: String
    var containerExtension: String?
    var plot: String?
    var duration: String?
    var coverURL: String?
}
