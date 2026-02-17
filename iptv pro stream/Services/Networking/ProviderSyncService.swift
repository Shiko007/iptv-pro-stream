import Foundation
import os

actor ProviderSyncService {
    static let shared = ProviderSyncService()

    private let networkClient = NetworkClient.shared
    private let m3uParser = M3UParser()

    func syncProvider(_ provider: Provider) async throws -> Provider {
        var updatedProvider = provider

        switch provider.type {
        case .m3u:
            try await syncM3UProvider(&updatedProvider)
        case .xtreamCodes:
            try await syncXtreamProvider(&updatedProvider)
        }

        updatedProvider.lastSynced = Date()
        return updatedProvider
    }

    // MARK: - M3U Sync

    private func syncM3UProvider(_ provider: inout Provider) async throws {
        guard let config = provider.m3uConfig,
              let url = URL(string: config.url) else {
            throw SyncError.invalidConfiguration
        }

        AppLogger.network.info("Fetching M3U playlist from \(config.url)")
        let content = try await networkClient.fetchString(from: url)

        let result = m3uParser.parse(content, providerID: provider.id)
        AppLogger.parser.info("Parsed \(result.channels.count) channels from M3U")

        // Update EPG URL if found in playlist
        if let epgURL = result.epgURL, provider.m3uConfig?.epgURL == nil {
            provider.m3uConfig?.epgURL = epgURL
        }

        // Cache channels to SwiftData
        let channelsToCache = result.channels
        let providerID = provider.id
        await MainActor.run {
            do {
                try DataManager.shared.cacheChannels(channelsToCache, for: providerID, streamType: .live)
            } catch {
                AppLogger.data.error("Failed to cache channels: \(error)")
            }
        }

        provider.channelCount = result.channels.count
    }

    // MARK: - Xtream Codes Sync

    private func syncXtreamProvider(_ provider: inout Provider) async throws {
        guard let config = provider.xtreamConfig else {
            throw SyncError.invalidConfiguration
        }

        let api = XtreamCodesAPI(config: config)

        // Authenticate first
        let auth = try await api.authenticate()
        guard auth.userInfo?.status == "Active" else {
            throw SyncError.authenticationFailed
        }

        AppLogger.network.info("Xtream auth successful for \(config.username)")

        // Fetch live streams
        let liveStreams = try await api.getLiveStreams()
        var channels: [Channel] = []

        for (index, stream) in liveStreams.enumerated() {
            guard let streamId = stream.streamId, let name = stream.name else { continue }
            let streamURL = api.liveStreamURL(streamID: streamId)
            var channel = Channel(
                id: "\(provider.id)-live-\(streamId)",
                name: name,
                logoURL: stream.streamIcon,
                groupTitle: stream.categoryId ?? "Uncategorized",
                streamURL: streamURL,
                streamType: .live,
                epgChannelID: stream.epgChannelId,
                providerID: provider.id,
                order: index
            )
            channel.streamID = streamId
            if let tvArchive = stream.tvArchive, tvArchive > 0 {
                channel.catchupDays = stream.tvArchiveDuration
            }
            channels.append(channel)
        }

        // Resolve category names
        let categories = try await api.getLiveCategories()
        let categoryMap = Dictionary(uniqueKeysWithValues: categories.map { ($0.categoryId, $0.categoryName) })
        channels = channels.map { channel in
            var ch = channel
            if let catName = categoryMap[ch.groupTitle] {
                ch.groupTitle = catName
            }
            return ch
        }

        // Cache live channels
        let liveChannelsToCache = channels
        let xtreamProviderID = provider.id
        await MainActor.run {
            do {
                try DataManager.shared.cacheChannels(liveChannelsToCache, for: xtreamProviderID, streamType: .live)
            } catch {
                AppLogger.data.error("Failed to cache Xtream live channels: \(error)")
            }
        }

        provider.channelCount = channels.count

        // Fetch and cache VOD streams
        do {
            let vodStreams = try await api.getVODStreams()
            let vodCategories = try await api.getVODCategories()
            let vodCategoryMap = Dictionary(uniqueKeysWithValues: vodCategories.map { ($0.categoryId, $0.categoryName) })

            var vodChannels: [Channel] = []
            for (index, vod) in vodStreams.enumerated() {
                guard let streamId = vod.streamId, let name = vod.name else { continue }
                let ext = vod.containerExtension ?? "mp4"
                let streamURL = api.vodStreamURL(streamID: streamId, extension: ext)
                let groupTitle = vod.categoryId.flatMap { vodCategoryMap[$0] } ?? "Uncategorized"
                var channel = Channel(
                    id: "\(provider.id)-movie-\(streamId)",
                    name: name,
                    logoURL: vod.streamIcon,
                    groupTitle: groupTitle,
                    streamURL: streamURL,
                    streamType: .movie,
                    providerID: provider.id,
                    order: index
                )
                channel.streamID = streamId
                channel.containerExtension = vod.containerExtension
                channel.plot = vod.plot
                channel.cast = vod.cast
                channel.director = vod.director
                channel.genre = vod.genre
                channel.rating = vod.rating
                channel.releaseDate = vod.releaseDate
                channel.duration = vod.duration
                vodChannels.append(channel)
            }

            let vodToCache = vodChannels
            await MainActor.run {
                do {
                    try DataManager.shared.cacheChannels(vodToCache, for: xtreamProviderID, streamType: .movie)
                } catch {
                    AppLogger.data.error("Failed to cache VOD channels: \(error)")
                }
            }
            provider.vodCount = vodChannels.count
        } catch {
            AppLogger.network.warning("Failed to fetch VOD: \(error)")
        }

        // Fetch and cache Series
        do {
            let seriesList = try await api.getSeries()
            let seriesCategories = try await api.getSeriesCategories()
            let seriesCategoryMap = Dictionary(uniqueKeysWithValues: seriesCategories.map { ($0.categoryId, $0.categoryName) })

            var seriesChannels: [Channel] = []
            for (index, series) in seriesList.enumerated() {
                guard let seriesId = series.seriesId, let name = series.name else { continue }
                let groupTitle = series.categoryId.flatMap { seriesCategoryMap[$0] } ?? "Uncategorized"
                var channel = Channel(
                    id: "\(provider.id)-series-\(seriesId)",
                    name: name,
                    logoURL: series.cover,
                    groupTitle: groupTitle,
                    streamURL: "",
                    streamType: .series,
                    providerID: provider.id,
                    order: index
                )
                channel.streamID = seriesId
                channel.plot = series.plot
                channel.cast = series.cast
                channel.director = series.director
                channel.genre = series.genre
                channel.rating = series.rating
                channel.releaseDate = series.releaseDate
                seriesChannels.append(channel)
            }

            let seriesToCache = seriesChannels
            await MainActor.run {
                do {
                    try DataManager.shared.cacheChannels(seriesToCache, for: xtreamProviderID, streamType: .series)
                } catch {
                    AppLogger.data.error("Failed to cache series channels: \(error)")
                }
            }
            provider.seriesCount = seriesChannels.count
        } catch {
            AppLogger.network.warning("Failed to fetch series: \(error)")
        }
    }
}

enum SyncError: LocalizedError, Sendable {
    case invalidConfiguration
    case authenticationFailed
    case parsingFailed
    case networkError(String)

    var errorDescription: String? {
        switch self {
        case .invalidConfiguration: return "Invalid provider configuration"
        case .authenticationFailed: return "Authentication failed"
        case .parsingFailed: return "Failed to parse playlist"
        case .networkError(let msg): return "Network error: \(msg)"
        }
    }
}
