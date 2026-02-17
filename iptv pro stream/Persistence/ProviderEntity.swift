import Foundation
import SwiftData

@Model
final class ProviderEntity {
    @Attribute(.unique) var id: UUID
    var name: String
    var typeRaw: String
    var configData: Data
    var isActive: Bool
    var lastSynced: Date?
    var channelCount: Int
    var vodCount: Int
    var seriesCount: Int
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \CachedChannelEntity.provider)
    var cachedChannels: [CachedChannelEntity]?

    init(from provider: Provider) {
        self.id = provider.id
        self.name = provider.name
        self.typeRaw = provider.type.rawValue
        self.isActive = provider.isActive
        self.lastSynced = provider.lastSynced
        self.channelCount = provider.channelCount
        self.vodCount = provider.vodCount
        self.seriesCount = provider.seriesCount
        self.createdAt = provider.createdAt

        if provider.type == .m3u, let config = provider.m3uConfig {
            self.configData = (try? JSONEncoder().encode(config)) ?? Data()
        } else if let config = provider.xtreamConfig {
            self.configData = (try? JSONEncoder().encode(config)) ?? Data()
        } else {
            self.configData = Data()
        }
    }

    func toProvider() -> Provider {
        let type = ProviderType(rawValue: typeRaw) ?? .m3u
        var provider = Provider(id: id, name: name, type: type)
        provider.isActive = isActive
        provider.lastSynced = lastSynced
        provider.channelCount = channelCount
        provider.vodCount = vodCount
        provider.seriesCount = seriesCount
        provider.createdAt = createdAt

        if type == .m3u {
            provider.m3uConfig = try? JSONDecoder().decode(M3UConfig.self, from: configData)
        } else {
            provider.xtreamConfig = try? JSONDecoder().decode(XtreamConfig.self, from: configData)
        }
        return provider
    }
}
