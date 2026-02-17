import SwiftUI

struct WatchProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(.black.opacity(0.5))
                Rectangle()
                    .fill(.red)
                    .frame(width: geo.size.width * min(max(progress, 0), 1))
            }
        }
        .frame(height: 3)
    }
}
