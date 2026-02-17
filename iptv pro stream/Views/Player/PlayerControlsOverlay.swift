import SwiftUI

struct PlayerControlsOverlay: View {
    let viewModel: PlayerViewModel
    let channelName: String
    let streamType: StreamType
    let onDismiss: () -> Void
    var onToggleFullScreen: (() -> Void)? = nil
    var isFullScreen: Bool = false
    var onNextEpisode: (() -> Void)? = nil
    @State private var showControls = true
    @State private var hideTask: Task<Void, Never>?
    @State private var isScrubbing = false
    @State private var scrubProgress: Double = 0

    private var effectiveProgress: Double {
        if isScrubbing { return scrubProgress }
        guard viewModel.duration > 0 else { return 0 }
        return viewModel.currentTime / viewModel.duration
    }

    private var displayTime: TimeInterval {
        if isScrubbing, viewModel.duration > 0 {
            return scrubProgress * viewModel.duration
        }
        return viewModel.currentTime
    }

    private var remainingTime: TimeInterval {
        max(0, viewModel.duration - displayTime)
    }

    private var isLive: Bool {
        streamType == .live
    }

    private var showNextEpisode: Bool {
        guard onNextEpisode != nil else { return false }
        guard viewModel.duration > 0 else { return false }
        return viewModel.duration - viewModel.currentTime <= Constants.Player.nextEpisodeThreshold
    }

    var body: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showControls.toggle()
                    }
                    if showControls { scheduleHide() }
                }

            // Next Episode button - always visible when near end, independent of controls
            if showNextEpisode, let action = onNextEpisode {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: action) {
                            Label("Next Episode", systemImage: "forward.fill")
                                .font(.headline)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(.ultraThinMaterial, in: Capsule())
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, bottomPadding + 70)
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }

            if showControls {
                LinearGradient(
                    stops: [
                        .init(color: .black.opacity(0.7), location: 0),
                        .init(color: .clear, location: 0.35),
                        .init(color: .clear, location: 0.65),
                        .init(color: .black.opacity(0.8), location: 1),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .allowsHitTesting(false)

                VStack(spacing: 0) {
                    topBar
                        .padding(.horizontal)
                        .padding(.top, 8)

                    Spacer()

                    centerControls

                    Spacer()

                    if !isLive {
                        bottomBar
                            .padding(.horizontal)
                            .padding(.bottom, bottomPadding)
                    } else {
                        liveIndicator
                            .padding(.horizontal)
                            .padding(.bottom, bottomPadding)
                    }
                }
            }
        }
        .onAppear { scheduleHide() }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 12) {
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(channelName)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(1)

                if case .error(let msg) = viewModel.playerState.playbackState {
                    Text(msg)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .lineLimit(1)
                }
            }

            Spacer()

            if viewModel.isBuffering {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
                    .scaleEffect(0.8)
            }
        }
    }

    // MARK: - Center Controls

    private var centerControls: some View {
        HStack(spacing: 50) {
            Button {
                viewModel.seekBackward()
                scheduleHide()
            } label: {
                Image(systemName: "gobackward.10")
                    .font(.title)
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .opacity(isLive ? 0.3 : 1)
            .disabled(isLive)

            Button {
                viewModel.togglePlayPause()
                scheduleHide()
            } label: {
                Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)

            Button {
                viewModel.seekForward()
                scheduleHide()
            } label: {
                Image(systemName: "goforward.10")
                    .font(.title)
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .opacity(isLive ? 0.3 : 1)
            .disabled(isLive)
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Text(formatTime(displayTime))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.9))

                scrubber

                Text("-\(formatTime(remainingTime))")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.9))
            }

            bottomActions
        }
    }

    // MARK: - Bottom Actions

    private var bottomActions: some View {
        HStack {
            Spacer()

            #if os(iOS) || os(macOS)
            if viewModel.playerState.currentEngine == .avPlayer {
                AirPlayButton()
                    .frame(width: 28, height: 28)
            }
            #endif

            #if os(macOS)
            if let onToggleFullScreen {
                Button {
                    onToggleFullScreen()
                    scheduleHide()
                } label: {
                    Image(systemName: isFullScreen
                          ? "arrow.down.right.and.arrow.up.left.square"
                          : "arrow.up.left.and.arrow.down.right.square")
                        .font(.title3)
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }
            #endif
        }
    }

    // MARK: - Scrubber

    private var scrubber: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let trackHeight: CGFloat = isScrubbing ? 6 : 4
            let thumbSize: CGFloat = isScrubbing ? 16 : 12
            let progress = min(max(effectiveProgress, 0), 1)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.white.opacity(0.3))
                    .frame(height: trackHeight)

                Capsule()
                    .fill(.white)
                    .frame(width: width * progress, height: trackHeight)

                Circle()
                    .fill(.white)
                    .frame(width: thumbSize, height: thumbSize)
                    .shadow(color: .black.opacity(0.3), radius: 2)
                    .offset(x: width * progress - thumbSize / 2)
            }
            .frame(height: 20)
            .contentShape(Rectangle())
            #if !os(tvOS)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isScrubbing {
                            isScrubbing = true
                            hideTask?.cancel()
                        }
                        let fraction = value.location.x / width
                        scrubProgress = min(max(fraction, 0), 1)
                    }
                    .onEnded { _ in
                        viewModel.seek(to: scrubProgress)
                        isScrubbing = false
                        scheduleHide()
                    }
            )
            #endif
            .animation(.easeInOut(duration: 0.15), value: isScrubbing)
        }
        .frame(height: 20)
    }

    // MARK: - Live Indicator

    private var liveIndicator: some View {
        VStack(spacing: 8) {
            HStack {
                Circle()
                    .fill(.red)
                    .frame(width: 8, height: 8)
                Text("LIVE")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                Spacer()
            }

            bottomActions
        }
    }

    // MARK: - Helpers

    private var bottomPadding: CGFloat {
        #if os(tvOS)
        60
        #else
        30
        #endif
    }

    private func scheduleHide() {
        hideTask?.cancel()
        guard !isScrubbing else { return }
        hideTask = Task {
            try? await Task.sleep(for: .seconds(Constants.Player.controlsAutoHideDelay))
            if !Task.isCancelled {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showControls = false
                }
            }
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        guard time.isFinite, time >= 0 else { return "0:00" }
        let totalSeconds = Int(time)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
}
