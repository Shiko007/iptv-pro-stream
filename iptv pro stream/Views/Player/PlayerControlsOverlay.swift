import SwiftUI

struct PlayerControlsOverlay: View {
    let viewModel: PlayerViewModel
    let channelName: String
    let onDismiss: () -> Void
    @State private var showControls = true
    @State private var hideTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            if showControls {
                VStack {
                    // Top bar
                    HStack {
                        Button(action: onDismiss) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)

                        Text(channelName)
                            .font(.headline)
                            .foregroundStyle(.white)

                        Spacer()
                    }
                    .padding()

                    Spacer()

                    // Bottom controls
                    HStack(spacing: 30) {
                        Spacer()

                        Button {
                            viewModel.seekBackward()
                        } label: {
                            Image(systemName: "gobackward.10")
                                .font(.title)
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)

                        Button {
                            viewModel.togglePlayPause()
                        } label: {
                            Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)

                        Button {
                            viewModel.seekForward()
                        } label: {
                            Image(systemName: "goforward.10")
                                .font(.title)
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)

                        Spacer()
                    }
                    .padding(.bottom, 40)
                }
                .background(
                    LinearGradient(
                        colors: [.black.opacity(0.7), .clear, .black.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation {
                showControls.toggle()
            }
            scheduleHide()
        }
        .onAppear {
            scheduleHide()
        }
    }

    private func scheduleHide() {
        hideTask?.cancel()
        hideTask = Task {
            try? await Task.sleep(for: .seconds(Constants.Player.controlsAutoHideDelay))
            if !Task.isCancelled {
                withAnimation {
                    showControls = false
                }
            }
        }
    }
}
