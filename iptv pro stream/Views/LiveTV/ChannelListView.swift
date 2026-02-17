import SwiftUI

struct ChannelListView: View {
    let channels: [Channel]
    let categories: [String]
    @Binding var selectedCategory: String?

    var body: some View {
        List {
            ForEach(channels) { channel in
                NavigationLink(value: channel) {
                    ChannelRowView(channel: channel)
                }
            }
        }
        .navigationDestination(for: Channel.self) { channel in
            VideoPlayerView(channel: channel)
        }
    }
}
