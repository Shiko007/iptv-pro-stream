import Foundation

actor NetworkClient {
    static let shared = NetworkClient()

    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = Constants.Network.requestTimeout
        config.timeoutIntervalForResource = Constants.Network.resourceTimeout
        config.httpAdditionalHeaders = ["User-Agent": "IPTVProStream/1.0"]
        self.session = URLSession(configuration: config)
    }

    func fetchData(from url: URL, headers: [String: String] = [:]) async throws -> Data {
        var request = URLRequest(url: url)
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(httpResponse.statusCode)
        }

        return data
    }

    func fetchString(from url: URL, headers: [String: String] = [:]) async throws -> String {
        let data = try await fetchData(from: url, headers: headers)
        guard let string = String(data: data, encoding: .utf8) else {
            throw NetworkError.decodingError
        }
        return string
    }

    func fetchJSON<T: Decodable & Sendable>(_ type: T.Type, from url: URL, headers: [String: String] = [:]) async throws -> T {
        let data = try await fetchData(from: url, headers: headers)
        let decoder = JSONDecoder()
        return try decoder.decode(type, from: data)
    }
}

enum NetworkError: LocalizedError, Sendable {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case decodingError
    case noData
    case timeout

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid server response"
        case .httpError(let code): return "HTTP error: \(code)"
        case .decodingError: return "Failed to decode response"
        case .noData: return "No data received"
        case .timeout: return "Request timed out"
        }
    }
}
