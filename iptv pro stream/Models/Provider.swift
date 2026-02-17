import Foundation

nonisolated enum ProviderType: String, Codable, CaseIterable, Sendable {
    case m3u
    case xtreamCodes
}

nonisolated struct M3UConfig: Codable, Sendable, Hashable {
    var url: String
    var epgURL: String?
}

nonisolated struct XtreamConfig: Codable, Sendable, Hashable {
    var host: String
    var port: String?
    var username: String
    var password: String

    var baseURL: String {
        var cleanHost = host.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if !cleanHost.hasPrefix("http://") && !cleanHost.hasPrefix("https://") {
            cleanHost = "http://\(cleanHost)"
        }
        return cleanHost
    }

    var playerAPIURL: String {
        "\(baseURL)/player_api.php"
    }

    var liveStreamURL: String {
        "\(baseURL)/live/\(username)/\(password)"
    }

    var vodStreamURL: String {
        "\(baseURL)/movie/\(username)/\(password)"
    }

    var seriesStreamURL: String {
        "\(baseURL)/series/\(username)/\(password)"
    }
}

nonisolated struct Provider: Identifiable, Codable, Sendable, Hashable {
    var id: UUID
    var name: String
    var type: ProviderType
    var m3uConfig: M3UConfig?
    var xtreamConfig: XtreamConfig?
    var isActive: Bool
    var lastSynced: Date?
    var channelCount: Int
    var vodCount: Int
    var seriesCount: Int
    var createdAt: Date

    init(id: UUID = UUID(), name: String, type: ProviderType, m3uConfig: M3UConfig? = nil, xtreamConfig: XtreamConfig? = nil) {
        self.id = id
        self.name = name
        self.type = type
        self.m3uConfig = m3uConfig
        self.xtreamConfig = xtreamConfig
        self.isActive = true
        self.lastSynced = nil
        self.channelCount = 0
        self.vodCount = 0
        self.seriesCount = 0
        self.createdAt = Date()
    }
}
