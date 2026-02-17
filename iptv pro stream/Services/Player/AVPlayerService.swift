import Foundation
import AVFoundation

@Observable
final class AVPlayerService {
    let player = AVPlayer()
    var isPlaying = false
    var currentTime: TimeInterval = 0
    var duration: TimeInterval = 0
    var isBuffering = false
    var error: String?

    private var timeObserver: Any?
    private var statusObservation: NSKeyValueObservation?
    private var bufferObservation: NSKeyValueObservation?

    func load(url: URL, headers: [String: String] = [:]) {
        let asset: AVURLAsset
        if !headers.isEmpty {
            asset = AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": headers])
        } else {
            asset = AVURLAsset(url: url)
        }

        let item = AVPlayerItem(asset: asset)
        player.replaceCurrentItem(with: item)
        setupObservers()
    }

    func play() {
        player.play()
    }

    func pause() {
        player.pause()
    }

    func seek(to time: TimeInterval) {
        player.seek(to: CMTime(seconds: time, preferredTimescale: 600))
    }

    func stop() {
        player.pause()
        player.replaceCurrentItem(with: nil)
        removeObservers()
    }

    private func setupObservers() {
        removeObservers()

        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            guard let self else { return }
            Task { @MainActor in
                self.currentTime = time.seconds
                if let item = self.player.currentItem, item.duration.isNumeric {
                    self.duration = item.duration.seconds
                }
            }
        }

        statusObservation = player.currentItem?.observe(\.status) { [weak self] item, _ in
            guard let self else { return }
            Task { @MainActor in
                if item.status == .failed {
                    self.error = item.error?.localizedDescription ?? "Playback failed"
                }
            }
        }

        bufferObservation = player.currentItem?.observe(\.isPlaybackBufferEmpty) { [weak self] item, _ in
            guard let self else { return }
            Task { @MainActor in
                self.isBuffering = item.isPlaybackBufferEmpty
            }
        }
    }

    private func removeObservers() {
        if let timeObserver { player.removeTimeObserver(timeObserver) }
        timeObserver = nil
        statusObservation?.invalidate()
        statusObservation = nil
        bufferObservation?.invalidate()
        bufferObservation = nil
    }

    deinit {
        if let timeObserver { player.removeTimeObserver(timeObserver) }
    }
}
