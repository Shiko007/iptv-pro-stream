import Foundation
import VLCKitSPM

@Observable
final class VLCPlayerService: NSObject {
    let mediaPlayer = VLCMediaPlayer()
    var isPlaying = false
    var currentTime: TimeInterval = 0
    var duration: TimeInterval = 0
    var isBuffering = false
    var error: String?

    private var pollTimer: Timer?

    override init() {
        super.init()
        mediaPlayer.delegate = self
    }

    func load(url: URL, headers: [String: String] = [:]) {
        let media: VLCMedia
        if !headers.isEmpty {
            var options = [String]()
            for (key, value) in headers {
                options.append(":http-header=\(key): \(value)")
            }
            media = VLCMedia(url: url)
            for option in options {
                media.addOption(option)
            }
        } else {
            media = VLCMedia(url: url)
        }

        mediaPlayer.media = media
        isBuffering = true
        error = nil
        mediaPlayer.play()
        startPolling()
    }

    func play() {
        mediaPlayer.play()
    }

    func pause() {
        mediaPlayer.pause()
    }

    func seek(to time: TimeInterval) {
        guard duration > 0 else { return }
        let position = Float(time / duration)
        mediaPlayer.position = min(max(position, 0), 1)
    }

    func stop() {
        stopPolling()
        mediaPlayer.stop()
        isPlaying = false
        currentTime = 0
        duration = 0
        isBuffering = false
    }

    private func startPolling() {
        stopPolling()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.updateTimeInfo()
            }
        }
    }

    private func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    private func updateTimeInfo() {
        let time = mediaPlayer.time
        let remaining = mediaPlayer.remainingTime

        let timeMs = time.intValue
        if timeMs > 0 {
            currentTime = TimeInterval(timeMs) / 1000.0
        }

        if let remainingMs = remaining?.intValue {
            let totalMs = Int(timeMs) + abs(Int(remainingMs))
            if totalMs > 0 {
                duration = TimeInterval(totalMs) / 1000.0
            }
        }
    }

    deinit {
        pollTimer?.invalidate()
    }
}

extension VLCPlayerService: VLCMediaPlayerDelegate {
    nonisolated func mediaPlayerStateChanged(_ notification: Notification) {
        Task { @MainActor in
            switch mediaPlayer.state {
            case .playing:
                isPlaying = true
                isBuffering = false
            case .paused:
                isPlaying = false
                isBuffering = false
            case .buffering:
                isBuffering = true
            case .ended:
                isPlaying = false
                isBuffering = false
                stopPolling()
            case .error:
                isPlaying = false
                isBuffering = false
                error = "VLC playback error"
                stopPolling()
            case .stopped:
                isPlaying = false
                isBuffering = false
            default:
                break
            }
        }
    }
}
