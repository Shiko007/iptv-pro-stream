import SwiftUI

struct AsyncCachedImage<Placeholder: View>: View {
    let url: String?
    let contentMode: ContentMode
    let placeholder: () -> Placeholder
    @State private var imageData: Data?
    @State private var loadFailed = false

    init(url: String?, contentMode: ContentMode = .fill, @ViewBuilder placeholder: @escaping () -> Placeholder) {
        self.url = url
        self.contentMode = contentMode
        self.placeholder = placeholder

        // Synchronously check memory cache so cached images display instantly
        if let url {
            let key = url as NSString
            if let entry = ImageCacheService.shared.memoryCache.object(forKey: key) {
                _imageData = State(initialValue: entry.data)
            }
        }
    }

    var body: some View {
        Group {
            if let imageData, let image = platformImage(from: imageData) {
                image
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else if loadFailed || url == nil {
                placeholder()
            } else {
                placeholder()
            }
        }
        .task(id: url) {
            guard imageData == nil else { return }
            guard let url, !url.isEmpty else {
                loadFailed = true
                return
            }
            if let data = await ImageCacheService.shared.image(for: url) {
                imageData = data
            } else {
                loadFailed = true
            }
        }
    }

    private func platformImage(from data: Data) -> Image? {
        #if os(macOS)
        guard let nsImage = NSImage(data: data) else { return nil }
        return Image(nsImage: nsImage)
        #else
        guard let uiImage = UIImage(data: data) else { return nil }
        return Image(uiImage: uiImage)
        #endif
    }
}
