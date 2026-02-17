import SwiftUI

struct ChannelCardView: View {
    let channel: Channel

    var body: some View {
        VStack(alignment: .leading) {
            AsyncCachedImage(url: channel.logoURL) {
                Image(systemName: "tv")
                    .font(.largeTitle)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.secondary.opacity(0.2))
            }
            .frame(width: 160, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))

            Text(channel.name)
                .font(.caption)
                .lineLimit(2)
                .frame(width: 160, alignment: .leading)
        }
    }
}
