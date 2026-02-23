import Foundation
import SwiftData

@Model
final class RecentlyWatchedEntity {
    @Attribute(.unique) var channelID: String
    var channelName: String
    var logoURL: String?
    var streamURL: String
    var streamTypeRaw: String
    var providerID: UUID
    var lastWatchedAt: Date
    var lastPosition: Double
    var duration: Double
    var groupTitle: String
    var streamID: Int?
    var hiddenFromContinueWatching: Bool = false

    init(from channel: Channel, position: Double = 0, duration: Double = 0) {
        self.channelID = channel.id
        self.channelName = channel.name
        self.logoURL = channel.logoURL
        self.streamURL = channel.streamURL
        self.streamTypeRaw = channel.streamType.rawValue
        self.providerID = channel.providerID
        self.lastWatchedAt = Date()
        self.lastPosition = position
        self.duration = duration
        self.groupTitle = channel.groupTitle
        self.streamID = channel.streamID
    }

    func toChannel() -> Channel {
        var channel = Channel(
            id: channelID,
            name: channelName,
            logoURL: logoURL,
            groupTitle: groupTitle,
            streamURL: streamURL,
            streamType: StreamType(rawValue: streamTypeRaw) ?? .live,
            providerID: providerID
        )
        channel.streamID = streamID
        return channel
    }
}
