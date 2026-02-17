import Foundation
import SwiftData

@Model
final class CachedChannelEntity {
    @Attribute(.unique) var id: String
    var name: String
    var logoURL: String?
    var groupTitle: String
    var streamURL: String
    var streamTypeRaw: String
    var epgChannelID: String?
    var catchupSource: String?
    var catchupDays: Int?
    var providerID: UUID
    var streamID: Int?
    var containerExtension: String?
    var order: Int

    // VOD/Series metadata
    var plot: String?
    var cast: String?
    var director: String?
    var genre: String?
    var rating: String?
    var releaseDate: String?
    var duration: String?

    var provider: ProviderEntity?

    init(from channel: Channel) {
        self.id = channel.id
        self.name = channel.name
        self.logoURL = channel.logoURL
        self.groupTitle = channel.groupTitle
        self.streamURL = channel.streamURL
        self.streamTypeRaw = channel.streamType.rawValue
        self.epgChannelID = channel.epgChannelID
        self.catchupSource = channel.catchupSource
        self.catchupDays = channel.catchupDays
        self.providerID = channel.providerID
        self.streamID = channel.streamID
        self.containerExtension = channel.containerExtension
        self.order = channel.order
        self.plot = channel.plot
        self.cast = channel.cast
        self.director = channel.director
        self.genre = channel.genre
        self.rating = channel.rating
        self.releaseDate = channel.releaseDate
        self.duration = channel.duration
    }

    func toChannel() -> Channel {
        var channel = Channel(
            id: id,
            name: name,
            logoURL: logoURL,
            groupTitle: groupTitle,
            streamURL: streamURL,
            streamType: StreamType(rawValue: streamTypeRaw) ?? .live,
            epgChannelID: epgChannelID,
            providerID: providerID,
            order: order
        )
        channel.catchupSource = catchupSource
        channel.catchupDays = catchupDays
        channel.streamID = streamID
        channel.containerExtension = containerExtension
        channel.plot = plot
        channel.cast = cast
        channel.director = director
        channel.genre = genre
        channel.rating = rating
        channel.releaseDate = releaseDate
        channel.duration = duration
        return channel
    }
}
