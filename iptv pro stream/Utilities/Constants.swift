import Foundation

nonisolated enum Constants {
    enum App {
        static let name = "IPTV Pro Stream"
        static let bundleID = "com.sandybytes.iptv-pro-stream"
    }

    enum Cache {
        static let maxMemoryCacheMB = 100
        static let maxDiskCacheMB = 500
        static let imageCacheDirectory = "ImageCache"
        static let epgCacheTTLHours = 6
    }

    enum Player {
        static let controlsAutoHideDelay: TimeInterval = 5.0
        static let seekInterval: TimeInterval = 10.0
        static let bufferingTimeout: TimeInterval = 30.0
        static let nextEpisodeThreshold: TimeInterval = 120
    }

    enum UI {
        static let channelGridColumns = 4
        static let cornerRadius: CGFloat = 12
        static let thumbnailSize: CGFloat = 80
        #if os(tvOS)
        static let defaultPadding: CGFloat = 40
        #else
        static let defaultPadding: CGFloat = 16
        #endif
    }

    enum Network {
        static let requestTimeout: TimeInterval = 30
        static let resourceTimeout: TimeInterval = 300
        static let maxRetries = 3
    }
}
