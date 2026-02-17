import Foundation

nonisolated enum StreamFormat: String, Sendable {
    case hls       // .m3u8
    case mpegts    // .ts
    case mp4
    case mkv
    case avi
    case flv
    case unknown

    init(fromURL url: String) {
        let lowered = url.lowercased()
        if lowered.contains(".m3u8") || lowered.contains("/live/") {
            self = .hls
        } else if lowered.hasSuffix(".ts") {
            self = .mpegts
        } else if lowered.hasSuffix(".mp4") {
            self = .mp4
        } else if lowered.hasSuffix(".mkv") {
            self = .mkv
        } else if lowered.hasSuffix(".avi") {
            self = .avi
        } else if lowered.hasSuffix(".flv") {
            self = .flv
        } else {
            self = .unknown
        }
    }

    var supportsAVPlayer: Bool {
        switch self {
        case .hls, .mp4: return true
        case .mpegts, .mkv, .avi, .flv, .unknown: return false
        }
    }
}

nonisolated struct StreamInfo: Sendable {
    var url: URL
    var format: StreamFormat
    var headers: [String: String]
    var title: String?
    var logoURL: String?
    var subtitleURL: URL?

    init(url: URL, headers: [String: String] = [:], title: String? = nil, logoURL: String? = nil) {
        self.url = url
        self.format = StreamFormat(fromURL: url.absoluteString)
        self.headers = headers
        self.title = title
        self.logoURL = logoURL
    }
}
