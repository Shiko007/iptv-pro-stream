import SwiftUI
import os

struct VideoPlayerView: View {
    @State private var channel: Channel
    @State private var episodes: [Episode]?
    @State private var currentEpisodeIndex: Int?
    @State private var viewModel: PlayerViewModel?
    @State private var vlcSyncTimer: Timer?
    @Environment(\.dismiss) private var dismiss
    #if os(macOS)
    private var fullScreenController = FullScreenPlayerController.shared
    #endif

    init(channel: Channel, episodes: [Episode]? = nil, currentEpisodeIndex: Int? = nil) {
        self._channel = State(initialValue: channel)
        self._episodes = State(initialValue: episodes)
        self._currentEpisodeIndex = State(initialValue: currentEpisodeIndex)
    }

    private var nextEpisode: Episode? {
        guard let episodes, let index = currentEpisodeIndex,
              index + 1 < episodes.count else { return nil }
        return episodes[index + 1]
    }


    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let viewModel, !viewModel.isResuming {
                Group {
                    if viewModel.playerState.currentEngine == .vlc,
                       let vlcService = viewModel.vlcService {
                        VLCPlayerRepresentable(service: vlcService)
                    } else {
                        AVPlayerRepresentable(viewModel: viewModel)
                    }
                }
                .ignoresSafeArea()

                PlayerControlsOverlay(
                    viewModel: viewModel,
                    channelName: channel.name,
                    streamType: channel.streamType,
                    onDismiss: {
                        #if os(macOS)
                        if fullScreenController.isFullScreen {
                            fullScreenController.exitFullScreen()
                        }
                        #endif
                        vlcSyncTimer?.invalidate()
                        vlcSyncTimer = nil
                        viewModel.stop()
                        dismiss()
                    },
                    onToggleFullScreen: {
                        #if os(macOS)
                        fullScreenController.toggle()
                        #endif
                    },
                    isFullScreen: isFullScreen,
                    onNextEpisode: nextEpisode != nil ? { playNextEpisode() } : nil
                )
            } else {
                ProgressView()
                    .foregroundStyle(.white)
            }
        }
        #if os(macOS)
        .navigationTitle("")
        .toolbar(isFullScreen ? .hidden : .automatic)
        #else
        .navigationBarHidden(true)
        #endif
        .task {
            guard viewModel == nil else { return }
            print("[RESUME-DEBUG] VideoPlayerView.task started")
            let vm = PlayerViewModel()
            // Pre-set isResuming before exposing vm to the view
            // so SwiftUI never renders a frame with the player visible before seek
            let hasSavedPosition = (try? DataManager.shared.fetchSavedPosition(for: channel.id)) != nil
            print("[RESUME-DEBUG] hasSavedPosition=\(hasSavedPosition)")
            if hasSavedPosition {
                vm.isResuming = true
            }
            print("[RESUME-DEBUG] Setting viewModel (isResuming=\(vm.isResuming))")
            self.viewModel = vm
            print("[RESUME-DEBUG] Calling vm.play()")
            await vm.play(channel: channel)
            print("[RESUME-DEBUG] vm.play() returned, isResuming=\(vm.isResuming)")
            startVLCSyncIfNeeded(vm)

            // Load episode list for series if not already provided
            if episodes == nil, channel.streamType == .series {
                await loadEpisodesForCurrentChannel()
            }
        }
        .onChange(of: viewModel?.playerState.playbackState) { _, newValue in
            if newValue == .ended {
                // Episode finished — dismiss back to series detail
                vlcSyncTimer?.invalidate()
                vlcSyncTimer = nil
                dismiss()
            }
        }
        .onDisappear {
            #if os(macOS)
            fullScreenController.exitFullScreen()
            #endif
            vlcSyncTimer?.invalidate()
            vlcSyncTimer = nil
            viewModel?.stop()
        }
    }

    private func playNextEpisode() {
        guard let next = nextEpisode, let index = currentEpisodeIndex else { return }
        let nextChannel = episodeToChannel(next)

        // Stop current playback
        vlcSyncTimer?.invalidate()
        vlcSyncTimer = nil
        viewModel?.stop()

        // Advance state
        currentEpisodeIndex = index + 1
        channel = nextChannel

        // Create new view model and start playback
        let vm = PlayerViewModel()
        self.viewModel = vm
        Task {
            await vm.play(channel: nextChannel)
            startVLCSyncIfNeeded(vm)
        }
    }

    private var seriesName: String {
        // Channel name format: "Series Name - S1E1 - Episode Title"
        if let range = channel.name.range(of: #" - S\d+E\d+"#, options: .regularExpression) {
            return String(channel.name[..<range.lowerBound])
        }
        return channel.name
    }

    private func episodeToChannel(_ episode: Episode) -> Channel {
        var ch = Channel(
            id: episode.id,
            name: "\(seriesName) - S\(episode.seasonNumber)E\(episode.episodeNumber) - \(episode.title)",
            logoURL: episode.coverURL ?? channel.logoURL,
            streamURL: episode.streamURL,
            streamType: .series,
            providerID: channel.providerID
        )
        ch.streamID = channel.streamID
        return ch
    }

    private func loadEpisodesForCurrentChannel() async {
        guard let seriesID = channel.streamID,
              let provider = try? DataManager.shared.fetchProviders().first(where: { $0.id == channel.providerID }),
              let config = provider.xtreamConfig else { return }

        do {
            let api = XtreamCodesAPI(config: config)
            let info = try await api.getSeriesInfo(seriesID: seriesID)
            guard let episodesDict = info.episodes else { return }

            // Find which season contains the current episode
            for (seasonKey, xtreamEpisodes) in episodesDict {
                let seasonNum = Int(seasonKey) ?? 0
                let seasonEpisodes = xtreamEpisodes.map { ep -> Episode in
                    let streamID = ep.id ?? "0"
                    let ext = ep.containerExtension ?? "mp4"
                    let url = api.seriesStreamURL(streamID: Int(streamID) ?? 0, extension: ext)
                    return Episode(
                        id: streamID,
                        title: ep.title ?? "Episode \(ep.episodeNum ?? 0)",
                        episodeNumber: ep.episodeNum ?? 0,
                        seasonNumber: ep.season ?? seasonNum,
                        streamURL: url,
                        containerExtension: ext,
                        plot: ep.info?.plot,
                        duration: ep.info?.duration,
                        coverURL: ep.info?.movieImage
                    )
                }.sorted { $0.episodeNumber < $1.episodeNumber }

                if let index = seasonEpisodes.firstIndex(where: { $0.id == channel.id }) {
                    episodes = seasonEpisodes
                    currentEpisodeIndex = index
                    return
                }
            }
        } catch {
            AppLogger.player.info("Could not load episode list: \(error.localizedDescription)")
        }
    }

    private var isFullScreen: Bool {
        #if os(macOS)
        fullScreenController.isFullScreen
        #else
        false
        #endif
    }

    private func startVLCSyncIfNeeded(_ vm: PlayerViewModel) {
        guard vm.playerState.currentEngine == .vlc else { return }
        vlcSyncTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            Task { @MainActor in
                vm.syncVLCState()
            }
        }
    }
}
