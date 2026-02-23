#if os(macOS)
import SwiftUI
import AppKit

@Observable
final class FullScreenPlayerController {
    static let shared = FullScreenPlayerController()
    var isFullScreen = false
    var isVideoPlaying = false

    private var observation: NSObjectProtocol?

    func enterFullScreen() {
        guard !isFullScreen, let window = NSApp.keyWindow else { return }

        observeWindowFullScreen(window)
        window.toggleFullScreen(nil)
    }

    func exitFullScreen() {
        guard isFullScreen, let window = NSApp.keyWindow ?? NSApp.windows.first(where: {
            $0.isVisible && $0.styleMask.contains(.fullScreen)
        }) else {
            isFullScreen = false
            return
        }

        window.toggleFullScreen(nil)
    }

    func toggle() {
        if isFullScreen {
            exitFullScreen()
        } else {
            enterFullScreen()
        }
    }

    private var enterObservation: NSObjectProtocol?

    private func observeWindowFullScreen(_ window: NSWindow) {
        if let observation { NotificationCenter.default.removeObserver(observation) }
        if let enterObservation { NotificationCenter.default.removeObserver(enterObservation) }

        enterObservation = NotificationCenter.default.addObserver(
            forName: NSWindow.didEnterFullScreenNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            self?.isFullScreen = true
        }

        observation = NotificationCenter.default.addObserver(
            forName: NSWindow.didExitFullScreenNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            self?.isFullScreen = false
        }
    }
}
#endif
