import Foundation
import SwiftData

@Observable
final class DataManager {
    let modelContainer: ModelContainer

    nonisolated static let shared: DataManager = {
        let manager = DataManager()
        return manager
    }()

    init() {
        let schema = Schema([
            ProviderEntity.self,
            CachedChannelEntity.self,
            FavoriteEntity.self,
            RecentlyWatchedEntity.self,
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: false)
        do {
            self.modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    @MainActor
    var modelContext: ModelContext {
        modelContainer.mainContext
    }

    // MARK: - Provider Operations

    @MainActor
    func fetchProviders() throws -> [Provider] {
        let descriptor = FetchDescriptor<ProviderEntity>(sortBy: [SortDescriptor(\.createdAt)])
        return try modelContext.fetch(descriptor).map { $0.toProvider() }
    }

    @MainActor
    func saveProvider(_ provider: Provider) throws {
        let descriptor = FetchDescriptor<ProviderEntity>(predicate: #Predicate { $0.id == provider.id })
        if let existing = try modelContext.fetch(descriptor).first {
            existing.name = provider.name
            existing.typeRaw = provider.type.rawValue
            existing.isActive = provider.isActive
            existing.lastSynced = provider.lastSynced
            existing.channelCount = provider.channelCount
            existing.vodCount = provider.vodCount
            existing.seriesCount = provider.seriesCount
            if provider.type == .m3u, let config = provider.m3uConfig {
                existing.configData = (try? JSONEncoder().encode(config)) ?? Data()
            } else if let config = provider.xtreamConfig {
                existing.configData = (try? JSONEncoder().encode(config)) ?? Data()
            }
        } else {
            modelContext.insert(ProviderEntity(from: provider))
        }
        try modelContext.save()
    }

    @MainActor
    func deleteProvider(_ providerID: UUID) throws {
        let descriptor = FetchDescriptor<ProviderEntity>(predicate: #Predicate { $0.id == providerID })
        if let entity = try modelContext.fetch(descriptor).first {
            modelContext.delete(entity)
        }
        // Also delete cached channels
        let channelDescriptor = FetchDescriptor<CachedChannelEntity>(predicate: #Predicate { $0.providerID == providerID })
        for channel in try modelContext.fetch(channelDescriptor) {
            modelContext.delete(channel)
        }
        try modelContext.save()
    }

    // MARK: - Channel Operations

    @MainActor
    func cacheChannels(_ channels: [Channel], for providerID: UUID, streamType: StreamType) throws {
        // Delete existing cached channels for this provider and stream type only
        let typeRaw = streamType.rawValue
        let descriptor = FetchDescriptor<CachedChannelEntity>(
            predicate: #Predicate { $0.providerID == providerID && $0.streamTypeRaw == typeRaw }
        )
        for entity in try modelContext.fetch(descriptor) {
            modelContext.delete(entity)
        }
        // Insert new channels
        for channel in channels {
            modelContext.insert(CachedChannelEntity(from: channel))
        }
        try modelContext.save()
    }

    @MainActor
    func fetchChannels(for providerID: UUID, streamType: StreamType? = nil) throws -> [Channel] {
        let typeRaw = streamType?.rawValue
        let descriptor: FetchDescriptor<CachedChannelEntity>
        if let typeRaw {
            descriptor = FetchDescriptor<CachedChannelEntity>(
                predicate: #Predicate { $0.providerID == providerID && $0.streamTypeRaw == typeRaw },
                sortBy: [SortDescriptor(\.order)]
            )
        } else {
            descriptor = FetchDescriptor<CachedChannelEntity>(
                predicate: #Predicate { $0.providerID == providerID },
                sortBy: [SortDescriptor(\.order)]
            )
        }
        return try modelContext.fetch(descriptor).map { $0.toChannel() }
    }

    @MainActor
    func fetchAllChannels(streamType: StreamType? = nil) throws -> [Channel] {
        let typeRaw = streamType?.rawValue
        let descriptor: FetchDescriptor<CachedChannelEntity>
        if let typeRaw {
            descriptor = FetchDescriptor<CachedChannelEntity>(
                predicate: #Predicate { $0.streamTypeRaw == typeRaw },
                sortBy: [SortDescriptor(\.order)]
            )
        } else {
            descriptor = FetchDescriptor<CachedChannelEntity>(sortBy: [SortDescriptor(\.order)])
        }
        return try modelContext.fetch(descriptor).map { $0.toChannel() }
    }

    // MARK: - Favorites

    @MainActor
    func toggleFavorite(_ channel: Channel) throws {
        let channelID = channel.id
        let descriptor = FetchDescriptor<FavoriteEntity>(predicate: #Predicate { $0.channelID == channelID })
        if let existing = try modelContext.fetch(descriptor).first {
            modelContext.delete(existing)
        } else {
            modelContext.insert(FavoriteEntity(from: channel))
        }
        try modelContext.save()
    }

    @MainActor
    func isFavorite(_ channelID: String) throws -> Bool {
        let descriptor = FetchDescriptor<FavoriteEntity>(predicate: #Predicate { $0.channelID == channelID })
        return try !modelContext.fetch(descriptor).isEmpty
    }

    @MainActor
    func fetchFavorites() throws -> [Channel] {
        let descriptor = FetchDescriptor<FavoriteEntity>(sortBy: [SortDescriptor(\.addedAt, order: .reverse)])
        return try modelContext.fetch(descriptor).map { $0.toChannel() }
    }

    // MARK: - Recently Watched

    @MainActor
    func updateRecentlyWatched(_ channel: Channel, position: Double = 0, duration: Double = 0) throws {
        let channelID = channel.id
        let descriptor = FetchDescriptor<RecentlyWatchedEntity>(predicate: #Predicate { $0.channelID == channelID })
        if let existing = try modelContext.fetch(descriptor).first {
            existing.lastWatchedAt = Date()
            existing.lastPosition = position
            existing.duration = duration
            existing.streamID = channel.streamID
        } else {
            modelContext.insert(RecentlyWatchedEntity(from: channel, position: position, duration: duration))
        }
        try modelContext.save()
    }

    @MainActor
    func fetchSavedPosition(for channelID: String) throws -> Double? {
        let descriptor = FetchDescriptor<RecentlyWatchedEntity>(predicate: #Predicate { $0.channelID == channelID })
        guard let entity = try modelContext.fetch(descriptor).first, entity.lastPosition > 0 else { return nil }
        return entity.lastPosition
    }

    @MainActor
    func removeRecentlyWatched(_ channelID: String) throws {
        let descriptor = FetchDescriptor<RecentlyWatchedEntity>(predicate: #Predicate { $0.channelID == channelID })
        if let entity = try modelContext.fetch(descriptor).first {
            modelContext.delete(entity)
            try modelContext.save()
        }
    }

    @MainActor
    func fetchRecentlyWatched(limit: Int = 20) throws -> [(channel: Channel, position: Double, duration: Double)] {
        var descriptor = FetchDescriptor<RecentlyWatchedEntity>(sortBy: [SortDescriptor(\.lastWatchedAt, order: .reverse)])
        descriptor.fetchLimit = limit
        return try modelContext.fetch(descriptor).map { ($0.toChannel(), $0.lastPosition, $0.duration) }
    }
}
