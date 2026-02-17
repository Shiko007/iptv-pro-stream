import Foundation
import SwiftData

@Model
final class FavoriteEntity {
    @Attribute(.unique) var channelID: String
    var channelName: String
    var logoURL: String?
    var groupTitle: String
    var streamURL: String
    var streamTypeRaw: String
    var providerID: UUID
    var addedAt: Date

    init(from channel: Channel) {
        self.channelID = channel.id
        self.channelName = channel.name
        self.logoURL = channel.logoURL
        self.groupTitle = channel.groupTitle
        self.streamURL = channel.streamURL
        self.streamTypeRaw = channel.streamType.rawValue
        self.providerID = channel.providerID
        self.addedAt = Date()
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
