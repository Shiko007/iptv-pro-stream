import SwiftUI

struct VODCardView: View {
    let item: VODItem

    var body: some View {
        VStack(alignment: .leading) {
            AsyncCachedImage(url: item.logoURL) {
                RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                    .fill(Color.secondary.opacity(0.2))
                    .overlay {
                        Image(systemName: "film")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                    }
            }
            .aspectRatio(2/3, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))

            Text(item.name)
                .font(.caption)
                .lineLimit(2)
        }
    }
}
