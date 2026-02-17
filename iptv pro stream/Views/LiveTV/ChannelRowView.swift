import SwiftUI

struct ChannelRowView: View {
    let channel: Channel

    var body: some View {
        HStack(spacing: 12) {
            AsyncCachedImage(url: channel.logoURL) {
                Image(systemName: "tv")
                    .font(.title2)
                    .frame(width: 50, height: 50)
                    .background(Color.secondary.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .frame(width: 50, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(channel.name)
                    .font(.headline)
                    .lineLimit(1)
                Text(channel.groupTitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}
