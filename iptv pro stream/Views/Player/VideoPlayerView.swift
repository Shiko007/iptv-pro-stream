import SwiftUI

struct VideoPlayerView: View {
    let channel: Channel
    @State private var viewModel: PlayerViewModel?
    @State private var vlcSyncTimer: Timer?
    @Environment(\.dismiss) private var dismiss
    #if os(macOS)
    private var fullScreenController = FullScreenPlayerController.shared
    #endif

    init(channel: Channel) {
        self.channel = channel
    }

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

                PlayerControlsOverlay(
                    viewModel: viewModel,
                    channelName: channel.name,
                    streamType: channel.streamType,
                    onDismiss: {
                        #if os(macOS)
                        if fullScreenController.isFullScreen {
                            fullScreenController.exitFullScreen()
                        }
                        #endif
                        vlcSyncTimer?.invalidate()
                        vlcSyncTimer = nil
                        viewModel.stop()
                        dismiss()
                    },
                    onToggleFullScreen: {
                        #if os(macOS)
                        fullScreenController.toggle()
                        #endif
                    },
                    isFullScreen: isFullScreen
                )
            } else {
                ProgressView("Loading...")
                    .foregroundStyle(.white)
            }
        }
        #if os(macOS)
        .navigationTitle("")
        .toolbar(isFullScreen ? .hidden : .automatic)
        #else
        .navigationBarHidden(true)
        #endif
        .task {
            guard viewModel == nil else { return }
            let vm = PlayerViewModel()
            self.viewModel = vm
            await vm.play(channel: channel)
            startVLCSyncIfNeeded(vm)
        }
        .onDisappear {
            #if os(macOS)
            fullScreenController.exitFullScreen()
            #endif
            vlcSyncTimer?.invalidate()
            vlcSyncTimer = nil
            viewModel?.stop()
        }
    }

    private var isFullScreen: Bool {
        #if os(macOS)
        fullScreenController.isFullScreen
        #else
        false
        #endif
    }

    private func startVLCSyncIfNeeded(_ vm: PlayerViewModel) {
        guard vm.playerState.currentEngine == .vlc else { return }
        vlcSyncTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            Task { @MainActor in
                vm.syncVLCState()
            }
        }
    }
}
