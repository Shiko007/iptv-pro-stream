import Foundation

nonisolated enum StreamType: String, Codable, Sendable {
    case live
    case movie
    case series
}

nonisolated struct Channel: Identifiable, Codable, Sendable, Hashable {
    var id: String
    var name: String
    var logoURL: String?
    var groupTitle: String
    var streamURL: String
    var streamType: StreamType
    var epgChannelID: String?
    var catchupSource: String?
    var catchupDays: Int?
    var providerID: UUID
    var streamID: Int?
    var containerExtension: String?
    var customHeaders: [String: String]?
    var order: Int

    // VOD/Series metadata
    var plot: String?
    var cast: String?
    var director: String?
    var genre: String?
    var rating: String?
    var releaseDate: String?
    var duration: String?

    init(id: String = UUID().uuidString, name: String, logoURL: String? = nil, groupTitle: String = "Uncategorized", streamURL: String, streamType: StreamType = .live, epgChannelID: String? = nil, providerID: UUID, order: Int = 0) {
        self.id = id
        self.name = name
        self.logoURL = logoURL
        self.groupTitle = groupTitle
        self.streamURL = streamURL
        self.streamType = streamType
        self.epgChannelID = epgChannelID
        self.providerID = providerID
        self.order = order
    }
}
