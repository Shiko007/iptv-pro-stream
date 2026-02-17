import SwiftUI

enum LoadingState<T: Sendable>: Sendable {
    case idle
    case loading
    case loaded(T)
    case error(String)
}

struct LoadingStateView<T: Sendable, Content: View>: View {
    let state: LoadingState<T>
    let content: (T) -> Content

    init(state: LoadingState<T>, @ViewBuilder content: @escaping (T) -> Content) {
        self.state = state
        self.content = content
    }

    var body: some View {
        switch state {
        case .idle:
            Color.clear
        case .loading:
            ProgressView()
        case .loaded(let data):
            content(data)
        case .error(let message):
            ContentUnavailableView(
                "Error",
                systemImage: "exclamationmark.triangle",
                description: Text(message)
            )
        }
    }
}
