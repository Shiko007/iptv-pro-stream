import SwiftUI
import VLCKitSPM

#if os(macOS)
struct VLCPlayerRepresentable: NSViewRepresentable {
    let service: VLCPlayerService

    func makeNSView(context: Context) -> VLCVideoView {
        let view = VLCVideoView()
        service.mediaPlayer.drawable = view
        return view
    }

    func updateNSView(_ nsView: VLCVideoView, context: Context) {}
}
#else
struct VLCPlayerRepresentable: UIViewRepresentable {
    let service: VLCPlayerService

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        service.mediaPlayer.drawable = view
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
#endif
