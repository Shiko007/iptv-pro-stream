import SwiftUI

struct VODCardView: View {
    let item: VODItem
    var progress: Double?

    var body: some View {
        VStack(alignment: .leading) {
            Color.clear
                .aspectRatio(2/3, contentMode: .fit)
                .overlay {
                    AsyncCachedImage(url: item.logoURL) {
                        RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                            .fill(Color.secondary.opacity(0.2))
                            .overlay {
                                Image(systemName: "film")
                                    .font(.largeTitle)
                                    .foregroundStyle(.secondary)
                            }
                    }
                }
                .overlay(alignment: .bottom) {
                    if let progress, progress > 0 {
                        WatchProgressBar(progress: progress)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))

            Text(item.name)
                .font(.caption)
                .lineLimit(2)
        }
        .contentShape(Rectangle())
    }
}
