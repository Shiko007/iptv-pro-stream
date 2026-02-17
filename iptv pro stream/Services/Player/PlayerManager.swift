import Foundation
import AVFoundation

@Observable
final class PlayerManager {
    static let shared = PlayerManager()

    var currentPlayerState = PlayerState()
    private(set) var avPlayerService: AVPlayerService?

    func prepareStream(_ channel: Channel) -> StreamInfo? {
        guard let url = URL(string: channel.streamURL) else { return nil }
        return StreamInfo(
            url: url,
            headers: channel.customHeaders ?? [:],
            title: channel.name,
            logoURL: channel.logoURL
        )
    }

    func detectFormat(from url: String) -> StreamFormat {
        StreamFormat(fromURL: url)
    }

    func shouldUseVLC(for format: StreamFormat) -> Bool {
        !format.supportsAVPlayer
    }
}
