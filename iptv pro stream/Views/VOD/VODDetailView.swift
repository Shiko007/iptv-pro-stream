import SwiftUI
import os

struct VODDetailView: View {
    let item: VODItem

    @State private var posterURL: String?
    @State private var backdropURL: String?
    @State private var fullPlot: String?
    @State private var fullCast: String?
    @State private var fullDirector: String?
    @State private var fullGenre: String?
    @State private var fullRating: String?
    @State private var fullDuration: String?
    @State private var fullReleaseDate: String?
    @State private var isLoadingInfo = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Poster — uses movieImage from get_vod_info if available
                AsyncCachedImage(url: displayPosterURL, contentMode: .fit) {
                    RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                        .fill(Color.secondary.opacity(0.2))
                        .aspectRatio(2/3, contentMode: .fit)
                        .frame(maxHeight: 400)
                        .overlay {
                            Image(systemName: "film")
                                .font(.system(size: 60))
                                .foregroundStyle(.secondary)
                        }
                }
                .frame(maxWidth: .infinity)
                .frame(maxHeight: 400)
                .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
                .padding(.horizontal)

                // Content
                VStack(alignment: .leading, spacing: 16) {
                    Text(item.name)
                        .font(.title.bold())

                    // Quick tags: year, genre capsules
                    metadataRow

                    // Play button
                    NavigationLink {
                        VideoPlayerView(channel: item.toChannel())
                    } label: {
                        Label("Play", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    // Info card
                    infoSection

                    // Synopsis
                    if let plot = displayPlot, !plot.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Synopsis")
                                .font(.headline)
                            Text(plot)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Cast
                    if let cast = displayCast, !cast.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Cast")
                                .font(.headline)
                            FlowLayout(spacing: 6) {
                                ForEach(castNames(from: cast), id: \.self) { name in
                                    Text(name)
                                        .font(.subheadline)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(.quaternary, in: Capsule())
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom)
            }
        }
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .navigationTitle(item.name)
        .task {
            await loadFullInfo()
        }
    }

    // MARK: - Display helpers (prefer fetched data, fall back to item)

    private var displayPosterURL: String? { posterURL ?? item.logoURL }
    private var displayPlot: String? { fullPlot ?? item.plot }
    private var displayCast: String? { fullCast ?? item.cast }
    private var displayDirector: String? { fullDirector ?? item.director }
    private var displayGenre: String? { fullGenre ?? item.genre }
    private var displayRating: String? { fullRating ?? item.rating }
    private var displayDuration: String? { fullDuration ?? item.duration }
    private var displayReleaseDate: String? { fullReleaseDate ?? item.releaseDate }

    private var displayYear: String? {
        guard let date = displayReleaseDate, !date.isEmpty else { return nil }
        // Extract 4-digit year from various date formats
        if let range = date.range(of: #"\d{4}"#, options: .regularExpression) {
            return String(date[range])
        }
        return nil
    }

    // MARK: - Fetch full movie info

    private func loadFullInfo() async {
        guard let streamID = item.seriesID ?? Int(item.id.components(separatedBy: "-").last ?? "") else { return }
        guard let provider = try? DataManager.shared.fetchProviders().first(where: { $0.id == item.providerID }),
              let config = provider.xtreamConfig else { return }

        isLoadingInfo = true
        defer { isLoadingInfo = false }

        do {
            let api = XtreamCodesAPI(config: config)
            let info = try await api.getVODInfo(vodID: streamID)
            if let data = info.info {
                posterURL = data.movieImage
                backdropURL = data.backdrop
                if let p = data.plot, !p.isEmpty { fullPlot = p }
                if let c = data.cast, !c.isEmpty { fullCast = c }
                if let d = data.director, !d.isEmpty { fullDirector = d }
                if let g = data.genre, !g.isEmpty { fullGenre = g }
                if let r = data.rating, !r.isEmpty { fullRating = r }
                if let d = data.duration, !d.isEmpty { fullDuration = d }
                if let r = data.releaseDate, !r.isEmpty { fullReleaseDate = r }
            }
        } catch {
            AppLogger.network.error("Failed to load VOD info: \(error)")
        }
    }

    // MARK: - Metadata row (year + genres)

    @ViewBuilder
    private var metadataRow: some View {
        let tags = metadataTags
        if !tags.isEmpty {
            FlowLayout(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.quaternary, in: Capsule())
                }
            }
        }
    }

    private var metadataTags: [String] {
        var tags: [String] = []
        if let year = displayYear {
            tags.append(year)
        }
        if let genre = displayGenre, !genre.isEmpty {
            for g in genre.components(separatedBy: ",") {
                let trimmed = g.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty { tags.append(trimmed) }
            }
        }
        return tags
    }

    // MARK: - Info card

    @ViewBuilder
    private var infoSection: some View {
        let rows = infoRows
        if !rows.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(rows, id: \.label) { row in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: row.icon)
                            .foregroundStyle(.secondary)
                            .frame(width: 20)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(row.label)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                            Text(row.value)
                                .font(.subheadline)
                        }
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
        }
    }

    private var infoRows: [(icon: String, label: String, value: String)] {
        var rows: [(icon: String, label: String, value: String)] = []
        if let rating = displayRating, !rating.isEmpty {
            rows.append(("star.fill", "Rating", rating))
        }
        if let duration = displayDuration, !duration.isEmpty {
            rows.append(("clock", "Duration", duration))
        }
        if let releaseDate = displayReleaseDate, !releaseDate.isEmpty {
            rows.append(("calendar", "Release Date", releaseDate))
        }
        if let director = displayDirector, !director.isEmpty {
            rows.append(("megaphone", "Director", director))
        }
        return rows
    }

    private func castNames(from cast: String) -> [String] {
        cast.components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
}

// Simple flow layout for metadata capsules
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var height: CGFloat = 0
        for (index, row) in rows.enumerated() {
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            height += rowHeight
            if index < rows.count - 1 { height += spacing }
        }
        return CGSize(width: proposal.width ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            var x = bounds.minX
            for subview in row {
                let size = subview.sizeThatFits(.unspecified)
                subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += rowHeight + spacing
        }
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[LayoutSubviews.Element]] {
        let maxWidth = proposal.width ?? .infinity
        var rows: [[LayoutSubviews.Element]] = [[]]
        var currentWidth: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentWidth + size.width > maxWidth && !rows[rows.count - 1].isEmpty {
                rows.append([])
                currentWidth = 0
            }
            rows[rows.count - 1].append(subview)
            currentWidth += size.width + spacing
        }
        return rows
    }
}
