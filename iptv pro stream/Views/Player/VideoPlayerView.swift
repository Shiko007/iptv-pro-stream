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

            if let viewModel, !viewModel.isResuming {
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
                ProgressView()
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
            print("[RESUME-DEBUG] VideoPlayerView.task started")
            let vm = PlayerViewModel()
            // Pre-set isResuming before exposing vm to the view
            // so SwiftUI never renders a frame with the player visible before seek
            let hasSavedPosition = (try? DataManager.shared.fetchSavedPosition(for: channel.id)) != nil
            print("[RESUME-DEBUG] hasSavedPosition=\(hasSavedPosition)")
            if hasSavedPosition {
                vm.isResuming = true
            }
            print("[RESUME-DEBUG] Setting viewModel (isResuming=\(vm.isResuming))")
            self.viewModel = vm
            print("[RESUME-DEBUG] Calling vm.play()")
            await vm.play(channel: channel)
            print("[RESUME-DEBUG] vm.play() returned, isResuming=\(vm.isResuming)")
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
