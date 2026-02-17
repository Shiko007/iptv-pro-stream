import SwiftUI
import AVKit

#if os(macOS)
struct AVPlayerRepresentable: NSViewRepresentable {
    let viewModel: PlayerViewModel

    func makeNSView(context: Context) -> AVPlayerView {
        let view = AVPlayerView()
        view.controlsStyle = .none
        view.player = viewModel.player
        return view
    }

    func updateNSView(_ nsView: AVPlayerView, context: Context) {
        nsView.player = viewModel.player
    }
}
#else
struct AVPlayerRepresentable: UIViewControllerRepresentable {
    let viewModel: PlayerViewModel

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = viewModel.player
        controller.showsPlaybackControls = false
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        uiViewController.player = viewModel.player
    }
}
#endif
