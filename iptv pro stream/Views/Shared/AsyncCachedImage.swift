import SwiftUI

struct AsyncCachedImage<Placeholder: View>: View {
    let url: String?
    let placeholder: () -> Placeholder

    init(url: String?, @ViewBuilder placeholder: @escaping () -> Placeholder) {
        self.url = url
        self.placeholder = placeholder
    }

    var body: some View {
        if let url, let imageURL = URL(string: url) {
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    placeholder()
                case .empty:
                    ProgressView()
                @unknown default:
                    placeholder()
                }
            }
        } else {
            placeholder()
        }
    }
}
