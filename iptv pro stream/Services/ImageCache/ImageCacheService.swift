import Foundation
import SwiftUI

actor ImageCacheService {
    static let shared = ImageCacheService()

    // NSCache is thread-safe, so it can be accessed outside the actor
    nonisolated(unsafe) let memoryCache = NSCache<NSString, CacheEntry>()
    private var activeFetches: [String: Task<Data?, Never>] = [:]
    private var concurrentCount = 0
    private let maxConcurrent = 6

    init() {
        memoryCache.totalCostLimit = Constants.Cache.maxMemoryCacheMB * 1024 * 1024

        // Clean up any leftover disk cache from previous versions
        let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        let oldCacheDir = paths[0].appendingPathComponent(Constants.Cache.imageCacheDirectory)
        try? FileManager.default.removeItem(at: oldCacheDir)
    }

    func image(for urlString: String) async -> Data? {
        let key = urlString as NSString

        // Check memory
        if let entry = memoryCache.object(forKey: key) {
            return entry.data
        }

        // Deduplicate in-flight requests
        if let existing = activeFetches[urlString] {
            return await existing.value
        }

        let task = Task<Data?, Never> {
            // Throttle concurrent network requests
            while concurrentCount >= maxConcurrent {
                await Task.yield()
                try? await Task.sleep(for: .milliseconds(50))
            }
            guard !Task.isCancelled else { return nil }

            concurrentCount += 1
            defer { concurrentCount -= 1 }

            guard let url = URL(string: urlString) else { return nil }
            do {
                let data = try await NetworkClient.shared.fetchData(from: url)
                memoryCache.setObject(CacheEntry(data: data), forKey: key, cost: data.count)
                return data
            } catch {
                return nil
            }
        }

        activeFetches[urlString] = task
        let result = await task.value
        activeFetches.removeValue(forKey: urlString)
        return result
    }

    func clearCache() {
        memoryCache.removeAllObjects()
    }
}

final class CacheEntry: NSObject {
    let data: Data
    init(data: Data) { self.data = data }
}
