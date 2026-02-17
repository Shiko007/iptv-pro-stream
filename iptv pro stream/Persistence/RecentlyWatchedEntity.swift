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
    }

    func toChannel() -> Channel {
        Channel(
            id: channelID,
            name: channelName,
            logoURL: logoURL,
            groupTitle: groupTitle,
            streamURL: streamURL,
            streamType: StreamType(rawValue: streamTypeRaw) ?? .live,
            providerID: providerID
        )
    }
}
