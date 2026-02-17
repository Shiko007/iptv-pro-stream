import Foundation

actor XtreamCodesAPI {
    private let config: XtreamConfig
    private let networkClient = NetworkClient.shared

    init(config: XtreamConfig) {
        self.config = config
    }

    private func apiURL(action: String, extraParams: [String: String] = [:]) -> URL? {
        var components = URLComponents(string: config.playerAPIURL)
        var queryItems = [
            URLQueryItem(name: "username", value: config.username),
            URLQueryItem(name: "password", value: config.password),
            URLQueryItem(name: "action", value: action)
        ]
        for (key, value) in extraParams {
            queryItems.append(URLQueryItem(name: key, value: value))
        }
        components?.queryItems = queryItems
        return components?.url
    }

    // MARK: - Authentication

    func authenticate() async throws -> XtreamAuthResponse {
        guard let url = apiURL(action: "") else { throw NetworkError.invalidURL }
        // For auth, we just need username/password without action
        var components = URLComponents(string: config.playerAPIURL)
        components?.queryItems = [
            URLQueryItem(name: "username", value: config.username),
            URLQueryItem(name: "password", value: config.password)
        ]
        guard let authURL = components?.url else { throw NetworkError.invalidURL }
        return try await networkClient.fetchJSON(XtreamAuthResponse.self, from: authURL)
    }

    // MARK: - Live TV

    func getLiveCategories() async throws -> [XtreamCategory] {
        guard let url = apiURL(action: "get_live_categories") else { throw NetworkError.invalidURL }
        return try await networkClient.fetchJSON([XtreamCategory].self, from: url)
    }

    func getLiveStreams(categoryID: String? = nil) async throws -> [XtreamStream] {
        var params: [String: String] = [:]
        if let categoryID { params["category_id"] = categoryID }
        guard let url = apiURL(action: "get_live_streams", extraParams: params) else { throw NetworkError.invalidURL }
        return try await networkClient.fetchJSON([XtreamStream].self, from: url)
    }

    // MARK: - VOD

    func getVODCategories() async throws -> [XtreamCategory] {
        guard let url = apiURL(action: "get_vod_categories") else { throw NetworkError.invalidURL }
        return try await networkClient.fetchJSON([XtreamCategory].self, from: url)
    }

    func getVODStreams(categoryID: String? = nil) async throws -> [XtreamVODStream] {
        var params: [String: String] = [:]
        if let categoryID { params["category_id"] = categoryID }
        guard let url = apiURL(action: "get_vod_streams", extraParams: params) else { throw NetworkError.invalidURL }
        return try await networkClient.fetchJSON([XtreamVODStream].self, from: url)
    }

    func getVODInfo(vodID: Int) async throws -> XtreamVODInfo {
        guard let url = apiURL(action: "get_vod_info", extraParams: ["vod_id": "\(vodID)"]) else { throw NetworkError.invalidURL }
        return try await networkClient.fetchJSON(XtreamVODInfo.self, from: url)
    }

    // MARK: - Series

    func getSeriesCategories() async throws -> [XtreamCategory] {
        guard let url = apiURL(action: "get_series_categories") else { throw NetworkError.invalidURL }
        return try await networkClient.fetchJSON([XtreamCategory].self, from: url)
    }

    func getSeries(categoryID: String? = nil) async throws -> [XtreamSeries] {
        var params: [String: String] = [:]
        if let categoryID { params["category_id"] = categoryID }
        guard let url = apiURL(action: "get_series", extraParams: params) else { throw NetworkError.invalidURL }
        return try await networkClient.fetchJSON([XtreamSeries].self, from: url)
    }

    func getSeriesInfo(seriesID: Int) async throws -> XtreamSeriesInfo {
        guard let url = apiURL(action: "get_series_info", extraParams: ["series_id": "\(seriesID)"]) else { throw NetworkError.invalidURL }
        return try await networkClient.fetchJSON(XtreamSeriesInfo.self, from: url)
    }

    // MARK: - EPG

    func getShortEPG(streamID: Int, limit: Int = 10) async throws -> XtreamEPGResponse {
        guard let url = apiURL(action: "get_short_epg", extraParams: ["stream_id": "\(streamID)", "limit": "\(limit)"]) else {
            throw NetworkError.invalidURL
        }
        return try await networkClient.fetchJSON(XtreamEPGResponse.self, from: url)
    }

    func getFullEPG(streamID: Int) async throws -> XtreamEPGResponse {
        guard let url = apiURL(action: "get_simple_data_table", extraParams: ["stream_id": "\(streamID)"]) else {
            throw NetworkError.invalidURL
        }
        return try await networkClient.fetchJSON(XtreamEPGResponse.self, from: url)
    }

    // MARK: - URL Construction

    func liveStreamURL(streamID: Int, extension ext: String = "m3u8") -> String {
        "\(config.liveStreamURL)/\(streamID).\(ext)"
    }

    func vodStreamURL(streamID: Int, extension ext: String) -> String {
        "\(config.vodStreamURL)/\(streamID).\(ext)"
    }

    func seriesStreamURL(streamID: Int, extension ext: String) -> String {
        "\(config.seriesStreamURL)/\(streamID).\(ext)"
    }

    func timeshiftURL(streamID: Int, start: String, duration: String) -> String {
        let base = config.baseURL
        return "\(base)/timeshift/\(config.username)/\(config.password)/\(duration)/\(start)/\(streamID).ts"
    }
}

// MARK: - Flexible Decoding Helpers

private extension KeyedDecodingContainer {
    /// Decodes a value that may arrive as either a String or a number from the Xtream API.
    func flexibleString(forKey key: Key) -> String? {
        if let string = try? decodeIfPresent(String.self, forKey: key) {
            return string
        }
        if let double = try? decodeIfPresent(Double.self, forKey: key) {
            if double.truncatingRemainder(dividingBy: 1) == 0 {
                return String(Int(double))
            }
            return String(double)
        }
        return nil
    }

    func flexibleInt(forKey key: Key) -> Int? {
        if let int = try? decodeIfPresent(Int.self, forKey: key) {
            return int
        }
        if let string = try? decodeIfPresent(String.self, forKey: key) {
            return Int(string)
        }
        return nil
    }
}

// MARK: - Xtream Response Models

nonisolated struct XtreamAuthResponse: Codable, Sendable {
    let userInfo: XtreamUserInfo?
    let serverInfo: XtreamServerInfo?

    enum CodingKeys: String, CodingKey {
        case userInfo = "user_info"
        case serverInfo = "server_info"
    }
}

nonisolated struct XtreamUserInfo: Codable, Sendable {
    let username: String?
    let password: String?
    let status: String?
    let expDate: String?
    let maxConnections: String?
    let activeCons: String?
    let createdAt: String?
    let isTrial: String?
    let allowedOutputFormats: [String]?

    enum CodingKeys: String, CodingKey {
        case username, password, status
        case expDate = "exp_date"
        case maxConnections = "max_connections"
        case activeCons = "active_cons"
        case createdAt = "created_at"
        case isTrial = "is_trial"
        case allowedOutputFormats = "allowed_output_formats"
    }
}

nonisolated struct XtreamServerInfo: Codable, Sendable {
    let url: String?
    let port: String?
    let httpsPort: String?
    let serverProtocol: String?
    let rtmpPort: String?
    let timezone: String?
    let timestampNow: Int?
    let timeNow: String?

    enum CodingKeys: String, CodingKey {
        case url, port, timezone
        case httpsPort = "https_port"
        case serverProtocol = "server_protocol"
        case rtmpPort = "rtmp_port"
        case timestampNow = "timestamp_now"
        case timeNow = "time_now"
    }
}

nonisolated struct XtreamCategory: Codable, Sendable, Identifiable {
    let categoryId: String
    let categoryName: String
    let parentId: Int?

    var id: String { categoryId }

    enum CodingKeys: String, CodingKey {
        case categoryId = "category_id"
        case categoryName = "category_name"
        case parentId = "parent_id"
    }
}

nonisolated struct XtreamStream: Codable, Sendable, Identifiable {
    let num: Int?
    let name: String?
    let streamType: String?
    let streamId: Int?
    let streamIcon: String?
    let epgChannelId: String?
    let added: String?
    let categoryId: String?
    let customSid: String?
    let tvArchive: Int?
    let directSource: String?
    let tvArchiveDuration: Int?

    var id: Int { streamId ?? 0 }

    enum CodingKeys: String, CodingKey {
        case num, name, added
        case streamType = "stream_type"
        case streamId = "stream_id"
        case streamIcon = "stream_icon"
        case epgChannelId = "epg_channel_id"
        case categoryId = "category_id"
        case customSid = "custom_sid"
        case tvArchive = "tv_archive"
        case directSource = "direct_source"
        case tvArchiveDuration = "tv_archive_duration"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        num = c.flexibleInt(forKey: .num)
        name = try c.decodeIfPresent(String.self, forKey: .name)
        streamType = try c.decodeIfPresent(String.self, forKey: .streamType)
        streamId = c.flexibleInt(forKey: .streamId)
        streamIcon = try c.decodeIfPresent(String.self, forKey: .streamIcon)
        epgChannelId = try c.decodeIfPresent(String.self, forKey: .epgChannelId)
        added = c.flexibleString(forKey: .added)
        categoryId = c.flexibleString(forKey: .categoryId)
        customSid = try c.decodeIfPresent(String.self, forKey: .customSid)
        tvArchive = c.flexibleInt(forKey: .tvArchive)
        directSource = try c.decodeIfPresent(String.self, forKey: .directSource)
        tvArchiveDuration = c.flexibleInt(forKey: .tvArchiveDuration)
    }
}

nonisolated struct XtreamVODStream: Codable, Sendable, Identifiable {
    let num: Int?
    let name: String?
    let streamType: String?
    let streamId: Int?
    let streamIcon: String?
    let added: String?
    let categoryId: String?
    let containerExtension: String?
    let rating: String?
    let plot: String?
    let cast: String?
    let director: String?
    let genre: String?
    let releaseDate: String?
    let duration: String?

    var id: Int { streamId ?? 0 }

    enum CodingKeys: String, CodingKey {
        case num, name, added, rating, plot, cast, director, genre, duration
        case streamType = "stream_type"
        case streamId = "stream_id"
        case streamIcon = "stream_icon"
        case categoryId = "category_id"
        case containerExtension = "container_extension"
        case releaseDate = "release_date"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        num = c.flexibleInt(forKey: .num)
        name = try c.decodeIfPresent(String.self, forKey: .name)
        streamType = try c.decodeIfPresent(String.self, forKey: .streamType)
        streamId = c.flexibleInt(forKey: .streamId)
        streamIcon = try c.decodeIfPresent(String.self, forKey: .streamIcon)
        added = c.flexibleString(forKey: .added)
        categoryId = c.flexibleString(forKey: .categoryId)
        containerExtension = try c.decodeIfPresent(String.self, forKey: .containerExtension)
        rating = c.flexibleString(forKey: .rating)
        plot = try c.decodeIfPresent(String.self, forKey: .plot)
        cast = try c.decodeIfPresent(String.self, forKey: .cast)
        director = try c.decodeIfPresent(String.self, forKey: .director)
        genre = try c.decodeIfPresent(String.self, forKey: .genre)
        releaseDate = try c.decodeIfPresent(String.self, forKey: .releaseDate)
        duration = c.flexibleString(forKey: .duration)
    }
}

nonisolated struct XtreamVODInfo: Codable, Sendable {
    let info: XtreamMovieData?
    let movieData: XtreamMovieStreamData?

    enum CodingKeys: String, CodingKey {
        case info
        case movieData = "movie_data"
    }
}

nonisolated struct XtreamMovieData: Codable, Sendable {
    let movieImage: String?
    let plot: String?
    let cast: String?
    let director: String?
    let genre: String?
    let releaseDate: String?
    let duration: String?
    let rating: String?
    let backdrop: String?

    enum CodingKeys: String, CodingKey {
        case plot, cast, director, genre, duration, rating, backdrop
        case movieImage = "movie_image"
        case releaseDate = "release_date"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        movieImage = try c.decodeIfPresent(String.self, forKey: .movieImage)
        plot = try c.decodeIfPresent(String.self, forKey: .plot)
        cast = try c.decodeIfPresent(String.self, forKey: .cast)
        director = try c.decodeIfPresent(String.self, forKey: .director)
        genre = try c.decodeIfPresent(String.self, forKey: .genre)
        releaseDate = try c.decodeIfPresent(String.self, forKey: .releaseDate)
        duration = c.flexibleString(forKey: .duration)
        rating = c.flexibleString(forKey: .rating)
        backdrop = try c.decodeIfPresent(String.self, forKey: .backdrop)
    }
}

nonisolated struct XtreamMovieStreamData: Codable, Sendable {
    let streamId: Int?
    let name: String?
    let containerExtension: String?

    enum CodingKeys: String, CodingKey {
        case name
        case streamId = "stream_id"
        case containerExtension = "container_extension"
    }
}

nonisolated struct XtreamSeries: Codable, Sendable, Identifiable {
    let num: Int?
    let name: String?
    let seriesId: Int?
    let cover: String?
    let plot: String?
    let cast: String?
    let director: String?
    let genre: String?
    let releaseDate: String?
    let rating: String?
    let categoryId: String?
    let lastModified: String?
    let backdrop: String?

    var id: Int { seriesId ?? 0 }

    enum CodingKeys: String, CodingKey {
        case num, name, cover, plot, cast, director, genre, rating, backdrop
        case seriesId = "series_id"
        case releaseDate = "release_date"
        case categoryId = "category_id"
        case lastModified = "last_modified"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        num = c.flexibleInt(forKey: .num)
        name = try c.decodeIfPresent(String.self, forKey: .name)
        seriesId = c.flexibleInt(forKey: .seriesId)
        cover = try c.decodeIfPresent(String.self, forKey: .cover)
        plot = try c.decodeIfPresent(String.self, forKey: .plot)
        cast = try c.decodeIfPresent(String.self, forKey: .cast)
        director = try c.decodeIfPresent(String.self, forKey: .director)
        genre = try c.decodeIfPresent(String.self, forKey: .genre)
        releaseDate = try c.decodeIfPresent(String.self, forKey: .releaseDate)
        rating = c.flexibleString(forKey: .rating)
        categoryId = c.flexibleString(forKey: .categoryId)
        lastModified = c.flexibleString(forKey: .lastModified)
        backdrop = try c.decodeIfPresent(String.self, forKey: .backdrop)
    }
}

nonisolated struct XtreamSeriesInfo: Codable, Sendable {
    let seasons: [XtreamSeason]?
    let info: XtreamSeriesData?
    let episodes: [String: [XtreamEpisode]]?
}

nonisolated struct XtreamSeriesData: Codable, Sendable {
    let name: String?
    let cover: String?
    let plot: String?
    let cast: String?
    let director: String?
    let genre: String?
    let releaseDate: String?
    let rating: String?
    let backdrop: String?
    let categoryId: String?

    enum CodingKeys: String, CodingKey {
        case name, cover, plot, cast, director, genre, rating, backdrop
        case releaseDate = "release_date"
        case categoryId = "category_id"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decodeIfPresent(String.self, forKey: .name)
        cover = try c.decodeIfPresent(String.self, forKey: .cover)
        plot = try c.decodeIfPresent(String.self, forKey: .plot)
        cast = try c.decodeIfPresent(String.self, forKey: .cast)
        director = try c.decodeIfPresent(String.self, forKey: .director)
        genre = try c.decodeIfPresent(String.self, forKey: .genre)
        releaseDate = try c.decodeIfPresent(String.self, forKey: .releaseDate)
        rating = c.flexibleString(forKey: .rating)
        backdrop = try c.decodeIfPresent(String.self, forKey: .backdrop)
        categoryId = c.flexibleString(forKey: .categoryId)
    }
}

nonisolated struct XtreamSeason: Codable, Sendable, Identifiable {
    let airDate: String?
    let episodeCount: Int?
    let id: Int
    let name: String?
    let overview: String?
    let seasonNumber: Int?
    let cover: String?

    enum CodingKeys: String, CodingKey {
        case id, name, overview, cover
        case airDate = "air_date"
        case episodeCount = "episode_count"
        case seasonNumber = "season_number"
    }
}

nonisolated struct XtreamEpisode: Codable, Sendable, Identifiable {
    let id: String?
    let episodeNum: Int?
    let title: String?
    let containerExtension: String?
    let info: XtreamEpisodeInfo?
    let season: Int?

    enum CodingKeys: String, CodingKey {
        case id, title, info, season
        case episodeNum = "episode_num"
        case containerExtension = "container_extension"
    }
}

nonisolated struct XtreamEpisodeInfo: Codable, Sendable {
    let plot: String?
    let duration: String?
    let movieImage: String?
    let rating: String?
    let releaseDate: String?

    enum CodingKeys: String, CodingKey {
        case plot, duration, rating
        case movieImage = "movie_image"
        case releaseDate = "release_date"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        plot = try c.decodeIfPresent(String.self, forKey: .plot)
        duration = c.flexibleString(forKey: .duration)
        movieImage = try c.decodeIfPresent(String.self, forKey: .movieImage)
        rating = c.flexibleString(forKey: .rating)
        releaseDate = try c.decodeIfPresent(String.self, forKey: .releaseDate)
    }
}

nonisolated struct XtreamEPGResponse: Codable, Sendable {
    let epgListings: [XtreamEPGListing]?

    enum CodingKeys: String, CodingKey {
        case epgListings = "epg_listings"
    }
}

nonisolated struct XtreamEPGListing: Codable, Sendable {
    let id: String?
    let epgId: String?
    let title: String?
    let lang: String?
    let start: String?
    let end: String?
    let description: String?
    let channelId: String?

    enum CodingKeys: String, CodingKey {
        case id, title, lang, start, end, description
        case epgId = "epg_id"
        case channelId = "channel_id"
    }
}
