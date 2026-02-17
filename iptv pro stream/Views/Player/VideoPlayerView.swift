import SwiftUI

struct VideoPlayerView: View {
    let channel: Channel
    @State private var viewModel: PlayerViewModel?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let viewModel {
                Group {
                    if viewModel.playerState.currentEngine == .vlc,
                       let vlcService = viewModel.vlcService {
                        VLCPlayerRepresentable(service: vlcService)
                    } else {
                        AVPlayerRepresentable(viewModel: viewModel)
                    }
                }
                .ignoresSafeArea()

                PlayerControlsOverlay(viewModel: viewModel, channelName: channel.name) {
                    dismiss()
                }
            } else {
                ProgressView("Loading...")
                    .foregroundStyle(.white)
            }
        }
        #if !os(macOS)
        .navigationBarHidden(true)
        #endif
        .task {
            let vm = PlayerViewModel()
            self.viewModel = vm
            await vm.play(channel: channel)
        }
        .onDisappear {
            viewModel?.stop()
        }
    }
}
