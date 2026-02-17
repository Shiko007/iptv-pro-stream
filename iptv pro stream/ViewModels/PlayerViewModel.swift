import Foundation
import AVFoundation
import Combine
import os

@Observable
final class PlayerViewModel {
    var playerState = PlayerState()
    var isPlaying = false
    var currentTime: TimeInterval = 0
    var duration: TimeInterval = 0
    var isBuffering = false
    var isResuming = false

    let player = AVPlayer()
    private(set) var vlcService: VLCPlayerService?

    private var timeObserver: Any?
    private var statusObservation: NSKeyValueObservation?
    private var rateObservation: NSKeyValueObservation?
    private var endObserver: NSObjectProtocol?
    private let dataManager = DataManager.shared
    private var currentChannel: Channel?
    private var pendingResumePosition: Double?

    func play(channel: Channel) async {
        currentChannel = channel
        guard let url = URL(string: channel.streamURL) else {
            playerState.playbackState = .error("Invalid URL")
            return
        }

        pendingResumePosition = try? dataManager.fetchSavedPosition(for: channel.id)
        isResuming = pendingResumePosition != nil
        if isResuming {
            player.isMuted = true
        }
        let format = StreamFormat(fromURL: channel.streamURL)
        let headers = channel.customHeaders ?? [:]

        AppLogger.player.info("Playing: \(url.absoluteString) (format: \(format.rawValue))")

        if PlayerManager.shared.shouldUseVLC(for: format) {
            playerState.currentEngine = .vlc
            let service = VLCPlayerService()
            vlcService = service
            playerState.playbackState = .loading
            service.load(url: url, headers: headers, muted: isResuming)
            isPlaying = true
        } else {
            playerState.currentEngine = .avPlayer
            await loadAndPlay(url: url, headers: headers)
            isPlaying = true
        }

        // For series, remove previous episodes of the same series so only the latest shows
        if channel.streamType == .series, let seriesID = channel.streamID {
            try? dataManager.removeRecentlyWatchedBySeries(seriesID: seriesID, except: channel.id)
        }
        try? dataManager.updateRecentlyWatched(channel)
    }

    private func loadAndPlay(url: URL, headers: [String: String]) async {
        playerState.playbackState = .loading

        let asset: AVURLAsset
        if !headers.isEmpty {
            asset = AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": headers])
        } else {
            asset = AVURLAsset(url: url)
        }

        let item = AVPlayerItem(asset: asset)
        player.replaceCurrentItem(with: item)
        observePlayer()

        if pendingResumePosition == nil {
            player.play()
        }
    }

    func togglePlayPause() {
        if playerState.currentEngine == .vlc, let vlc = vlcService {
            // Query actual VLC player state, not cached property
            if vlc.isActuallyPlaying {
                vlc.pause()
                isPlaying = false
                playerState.playbackState = .paused
            } else {
                vlc.play()
                isPlaying = true
                playerState.playbackState = .playing
            }
        } else {
            // Query actual AVPlayer rate
            if player.rate > 0 {
                player.pause()
                isPlaying = false
                playerState.playbackState = .paused
            } else {
                player.play()
                isPlaying = true
                playerState.playbackState = .playing
            }
        }
    }

    func seekForward() {
        if playerState.currentEngine == .vlc, let vlc = vlcService {
            vlc.seek(to: vlc.currentTime + Constants.Player.seekInterval)
        } else {
            let newTime = CMTime(seconds: currentTime + Constants.Player.seekInterval, preferredTimescale: 600)
            player.seek(to: newTime)
        }
    }

    func seekBackward() {
        if playerState.currentEngine == .vlc, let vlc = vlcService {
            vlc.seek(to: max(0, vlc.currentTime - Constants.Player.seekInterval))
        } else {
            let newTime = CMTime(seconds: max(0, currentTime - Constants.Player.seekInterval), preferredTimescale: 600)
            player.seek(to: newTime)
        }
    }

    func seek(to progress: Double) {
        if playerState.currentEngine == .vlc, let vlc = vlcService {
            guard vlc.duration > 0 else { return }
            vlc.seek(to: vlc.duration * progress)
        } else {
            guard duration > 0 else { return }
            let newTime = CMTime(seconds: duration * progress, preferredTimescale: 600)
            player.seek(to: newTime)
        }
    }

    func stop() {
        if let channel = currentChannel, duration > 0 {
            let remaining = duration - currentTime
            if remaining <= Constants.Player.nextEpisodeThreshold {
                // Near the end — remove from continue watching
                try? dataManager.removeRecentlyWatched(channel.id)
            } else {
                try? dataManager.updateRecentlyWatched(channel, position: currentTime, duration: duration)
            }
        }

        if playerState.currentEngine == .vlc {
            vlcService?.stop()
            vlcService = nil
        } else {
            player.pause()
            player.replaceCurrentItem(with: nil)
            removeObservers()
        }
    }

    // MARK: - Sync VLC state

    func syncVLCState() {
        guard playerState.currentEngine == .vlc, let vlc = vlcService else { return }

        if let position = pendingResumePosition, vlc.duration > 0 {
            pendingResumePosition = nil
            vlc.seek(to: position)
            vlc.unmute()
            isResuming = false
        }

        let actuallyPlaying = vlc.isActuallyPlaying
        isPlaying = actuallyPlaying
        currentTime = vlc.currentTime
        duration = vlc.duration
        isBuffering = vlc.isBuffering

        if let vlcError = vlc.error {
            playerState.playbackState = .error(vlcError)
        } else if vlc.isEnded {
            playerState.playbackState = .ended
        } else if vlc.isBuffering {
            playerState.playbackState = .buffering
        } else if actuallyPlaying {
            playerState.playbackState = .playing
        } else if vlc.currentTime > 0 {
            playerState.playbackState = .paused
        }
    }

    // MARK: - AVPlayer Observers

    private func observePlayer() {
        removeObservers()

        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            guard let self else { return }
            Task { @MainActor in
                self.currentTime = time.seconds
                if let duration = self.player.currentItem?.duration, duration.isNumeric {
                    self.duration = duration.seconds
                }
            }
        }

        statusObservation = player.currentItem?.observe(\.status, options: [.new]) { [weak self] item, _ in
            guard let self else { return }
            Task { @MainActor in
                switch item.status {
                case .readyToPlay:
                    if let position = self.pendingResumePosition {
                        self.pendingResumePosition = nil
                        let seekTime = CMTime(seconds: position, preferredTimescale: 600)
                        self.player.seek(to: seekTime, toleranceBefore: .zero, toleranceAfter: .zero) { finished in
                            Task { @MainActor in
                                self.player.isMuted = false
                                self.isResuming = false
                                self.player.play()
                                self.playerState.playbackState = .playing
                            }
                        }
                    } else {
                        self.playerState.playbackState = .playing
                    }
                case .failed:
                    let errorMsg = item.error?.localizedDescription ?? "Playback failed"
                    AppLogger.player.error("Playback failed: \(errorMsg)")
                    self.playerState.playbackState = .error(errorMsg)
                default:
                    break
                }
            }
        }

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.isPlaying = false
                self.playerState.playbackState = .ended
            }
        }

        rateObservation = player.observe(\.rate, options: [.new]) { [weak self] player, _ in
            guard let self else { return }
            Task { @MainActor in
                guard !self.isResuming else { return }
                self.isPlaying = player.rate > 0
                if player.rate > 0 {
                    self.playerState.playbackState = .playing
                } else if self.playerState.playbackState == .playing {
                    self.playerState.playbackState = .paused
                }
            }
        }
    }

    private func removeObservers() {
        if let timeObserver {
            player.removeTimeObserver(timeObserver)
        }
        timeObserver = nil
        statusObservation?.invalidate()
        statusObservation = nil
        rateObservation?.invalidate()
        rateObservation = nil
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
        endObserver = nil
    }

    deinit {
        if let timeObserver {
            player.removeTimeObserver(timeObserver)
        }
    }
}
