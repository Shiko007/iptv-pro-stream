import SwiftUI

struct VODDetailView: View {
    let item: VODItem

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header with poster
                HStack(alignment: .top, spacing: 16) {
                    AsyncCachedImage(url: item.logoURL) {
                        RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                            .fill(Color.secondary.opacity(0.2))
                            .overlay {
                                Image(systemName: "film")
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

                        if let duration = item.duration {
                            Label(duration, systemImage: "clock")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        if let releaseDate = item.releaseDate {
                            Label(releaseDate, systemImage: "calendar")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal)

                // Play button
                NavigationLink {
                    VideoPlayerView(channel: item.toChannel())
                } label: {
                    Label("Play", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
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

                // Cast & Crew
                if let cast = item.cast, !cast.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Cast")
                            .font(.headline)
                        Text(cast)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                }

                if let director = item.director, !director.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Director")
                            .font(.headline)
                        Text(director)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(item.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
