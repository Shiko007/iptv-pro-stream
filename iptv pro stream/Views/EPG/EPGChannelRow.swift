import SwiftUI

struct EPGChannelRow: View {
    let channelID: String
    let channelName: String
    let programmes: [EPGProgramme]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(channelName)
                .font(.headline)
                .padding(.horizontal)
                .padding(.top, 8)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 2) {
                    ForEach(programmes) { programme in
                        EPGProgrammeCell(programme: programme)
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: 80)
        }
    }
}
