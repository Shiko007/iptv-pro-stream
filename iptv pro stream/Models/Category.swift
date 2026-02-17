import Foundation

nonisolated struct Category: Identifiable, Codable, Sendable, Hashable {
    var id: String
    var name: String
    var parentID: String?
    var providerID: UUID
    var streamType: StreamType
    var channelCount: Int

    init(id: String, name: String, parentID: String? = nil, providerID: UUID, streamType: StreamType, channelCount: Int = 0) {
        self.id = id
        self.name = name
        self.parentID = parentID
        self.providerID = providerID
        self.streamType = streamType
        self.channelCount = channelCount
    }
}
