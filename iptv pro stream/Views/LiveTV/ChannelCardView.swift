import SwiftUI

struct ChannelCardView: View {
    let channel: Channel
    var progress: Double?

    var body: some View {
        VStack(alignment: .leading) {
            Color.clear
                .aspectRatio(16/10, contentMode: .fit)
                .overlay {
                    AsyncCachedImage(url: channel.logoURL) {
                        Image(systemName: "tv")
                            .font(.largeTitle)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.secondary.opacity(0.2))
                    }
                }
                .overlay(alignment: .bottom) {
                    if let progress, progress > 0 {
                        WatchProgressBar(progress: progress)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))

            Text(channel.name)
                .font(.caption)
                .lineLimit(2)
        }
        .contentShape(Rectangle())
    }
}
