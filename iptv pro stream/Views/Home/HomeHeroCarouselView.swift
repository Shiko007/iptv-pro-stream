import SwiftUI

struct HomeHeroCarouselView: View {
    let items: [VODItem]
    @State private var currentIndex = 0

    var body: some View {
        if !items.isEmpty {
            VStack(spacing: 8) {
                #if os(iOS)
                TabView(selection: $currentIndex) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        HeroSlideView(item: item)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .aspectRatio(16/9, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
                .padding(.horizontal)
                #else
                // macOS and tvOS: horizontal scroll with snap
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 0) {
                        ForEach(Array(items.enumerated()), id: \.element.id) { _, item in
                            HeroSlideView(item: item)
                                .containerRelativeFrame(.horizontal)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .aspectRatio(16/9, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
                #if os(macOS)
                .padding(.horizontal)
                #endif
                #endif

                // Page indicator dots
                HStack(spacing: 6) {
                    ForEach(0..<items.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentIndex ? Color.primary : Color.secondary.opacity(0.4))
                            .frame(width: 6, height: 6)
                    }
                }
            }
            .task(id: currentIndex) {
                guard items.count > 1 else { return }
                try? await Task.sleep(for: .seconds(6))
                guard !Task.isCancelled else { return }
                withAnimation {
                    currentIndex = (currentIndex + 1) % items.count
                }
            }
        }
    }
}
