import Foundation
import SwiftUI

actor ImageCacheService {
    static let shared = ImageCacheService()

    private let memoryCache = NSCache<NSString, CacheEntry>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL

    init() {
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = paths[0].appendingPathComponent(Constants.Cache.imageCacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        memoryCache.totalCostLimit = Constants.Cache.maxMemoryCacheMB * 1024 * 1024
    }

    func image(for urlString: String) async -> Data? {
        let key = urlString as NSString

        // Check memory
        if let entry = memoryCache.object(forKey: key) {
            return entry.data
        }

        // Check disk
        let fileURL = cacheDirectory.appendingPathComponent(urlString.hash.description)
        if let data = try? Data(contentsOf: fileURL) {
            memoryCache.setObject(CacheEntry(data: data), forKey: key, cost: data.count)
            return data
        }

        // Fetch from network
        guard let url = URL(string: urlString) else { return nil }
        do {
            let data = try await NetworkClient.shared.fetchData(from: url)
            memoryCache.setObject(CacheEntry(data: data), forKey: key, cost: data.count)
            try? data.write(to: fileURL)
            return data
        } catch {
            return nil
        }
    }

    func clearCache() {
        memoryCache.removeAllObjects()
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
}

private final class CacheEntry: NSObject {
    let data: Data
    init(data: Data) { self.data = data }
}
