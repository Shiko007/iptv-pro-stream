import SwiftUI
import os

struct SeriesDetailView: View {
    let item: VODItem

    @State private var isFavorite = false
    @State private var selectedSeason: Int = 1
    @State private var seasons: [Season] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var watchProgress: [String: Double] = [:]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack(alignment: .top, spacing: 16) {
                    AsyncCachedImage(url: item.logoURL) {
                        RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                            .fill(Color.secondary.opacity(0.2))
                            .overlay {
                                Image(systemName: "tv")
                                    .font(.largeTitle)
                                    .foregroundStyle(.secondary)
                            }
                    }
                    .frame(width: 150, height: 225)
                    .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))

                    VStack(alignment: .leading, spacing: 8) {
                        Text(item.name)
                            .font(.title2.bold())

                        if let genre = item.genre {
                            Text(genre)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        if let rating = item.rating {
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(.yellow)
                                Text(rating)
                            }
                            .font(.subheadline)
                        }

                        if !seasons.isEmpty {
                            Text("\(seasons.count) Seasons")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal)

                // Plot
                if let plot = item.plot, !plot.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Synopsis")
                            .font(.headline)
                        Text(plot)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                }

                // Loading / Error / Content
                if isLoading {
                    ProgressView("Loading episodes...")
                        .frame(maxWidth: .infinity)
                        .padding()
                } else if let errorMessage {
                    ContentUnavailableView(
                        "Failed to Load",
                        systemImage: "exclamationmark.triangle",
                        description: Text(errorMessage)
                    )
                } else if !seasons.isEmpty {
                    // Season picker
                    Picker("Season", selection: $selectedSeason) {
                        ForEach(seasons) { season in
                            Text(season.name).tag(season.seasonNumber)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // Episodes
                    if let season = seasons.first(where: { $0.seasonNumber == selectedSeason }) {
                        LazyVStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(season.episodes.enumerated()), id: \.element.id) { index, episode in
                                NavigationLink {
                                    VideoPlayerView(
                                        channel: episodeToChannel(episode),
                                        episodes: season.episodes,
                                        currentEpisodeIndex: index
                                    )
                                } label: {
                                    EpisodeRowView(episode: episode, progress: watchProgress[episode.id])
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(item.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    try? DataManager.shared.toggleFavorite(item.toChannel())
                    isFavorite.toggle()
                } label: {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(isFavorite ? .red : .secondary)
                }
            }
        }
        .onAppear {
            isFavorite = (try? DataManager.shared.isFavorite(item.id)) ?? false
            watchProgress = (try? DataManager.shared.fetchWatchProgress()) ?? [:]
            guard seasons.isEmpty, !isLoading else { return }
            Task { await loadEpisodes() }
        }
        .onReceive(NotificationCenter.default.publisher(for: PlayerViewModel.didStopPlayback)) { _ in
            watchProgress = (try? DataManager.shared.fetchWatchProgress()) ?? [:]
        }
    }

    private func loadEpisodes() async {
        guard let seriesID = item.seriesID else {
            errorMessage = "Missing series ID"
            return
        }

        // Look up the provider to get xtream config
        guard let provider = try? DataManager.shared.fetchProviders().first(where: { $0.id == item.providerID }),
              let config = provider.xtreamConfig else {
            errorMessage = "Provider not found"
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let api = XtreamCodesAPI(config: config)
            let info = try await api.getSeriesInfo(seriesID: seriesID)

            guard let episodesDict = info.episodes else {
                errorMessage = "No episodes found"
                return
            }

            // Build seasons from the episodes dictionary (keyed by season number)
            var loadedSeasons: [Season] = []
            for (seasonKey, xtreamEpisodes) in episodesDict {
                let seasonNum = Int(seasonKey) ?? 0
                let episodes = xtreamEpisodes.map { ep -> Episode in
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

                // Find matching season info for the name
                let seasonInfo = info.seasons?.first { $0.seasonNumber == seasonNum }
                let seasonName = seasonInfo?.name ?? "Season \(seasonNum)"

                loadedSeasons.append(Season(
                    id: seasonNum,
                    name: seasonName,
                    seasonNumber: seasonNum,
                    episodes: episodes,
                    coverURL: seasonInfo?.cover
                ))
            }

            seasons = loadedSeasons.sorted { $0.seasonNumber < $1.seasonNumber }
            if let first = seasons.first {
                selectedSeason = first.seasonNumber
            }
        } catch {
            errorMessage = error.localizedDescription
            AppLogger.data.error("Failed to load series info: \(error)")
        }
    }

    private func episodeToChannel(_ episode: Episode) -> Channel {
        var channel = Channel(
            id: episode.id,
            name: "\(item.name) - S\(episode.seasonNumber)E\(episode.episodeNumber) - \(episode.title)",
            logoURL: episode.coverURL ?? item.logoURL,
            streamURL: episode.streamURL,
            streamType: .series,
            providerID: item.providerID
        )
        channel.streamID = item.seriesID
        return channel
    }
}

struct EpisodeRowView: View {
    let episode: Episode
    var progress: Double?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("E\(episode.episodeNumber) - \(episode.title)")
                        .font(.headline)
                    if let duration = episode.duration {
                        Text(duration)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let plot = episode.plot {
                        Text(plot)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                Spacer()
                Image(systemName: "play.circle")
                    .font(.title2)
                    .foregroundStyle(.tint)
            }
            .padding(.vertical, 4)

            if let progress, progress > 0 {
                WatchProgressBar(progress: progress)
                    .padding(.top, 4)
            }
        }
    }
}
