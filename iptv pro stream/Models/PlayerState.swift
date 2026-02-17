import Foundation

nonisolated enum PlaybackState: Sendable, Equatable {
    case idle
    case loading
    case playing
    case paused
    case buffering
    case error(String)
    case ended

    var isActive: Bool {
        switch self {
        case .playing, .paused, .buffering: return true
        default: return false
        }
    }
}

nonisolated enum PlayerEngine: String, Sendable, CaseIterable {
    case avPlayer = "AVPlayer"
    case vlc = "VLC"
}

nonisolated struct PlayerState: Sendable {
    var playbackState: PlaybackState = .idle
    var currentTime: TimeInterval = 0
    var duration: TimeInterval = 0
    var bufferedTime: TimeInterval = 0
    var volume: Float = 1.0
    var rate: Float = 1.0
    var currentEngine: PlayerEngine = .avPlayer
    var streamInfo: StreamInfo?
    var errorMessage: String?

    var progress: Double {
        guard duration > 0 else { return 0 }
        return currentTime / duration
    }

    var remainingTime: TimeInterval {
        max(0, duration - currentTime)
    }

    var isLiveStream: Bool {
        duration <= 0
    }
}
