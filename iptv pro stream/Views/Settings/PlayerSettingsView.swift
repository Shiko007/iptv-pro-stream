import SwiftUI

struct PlayerSettingsView: View {
    @AppStorage("preferredPlayer") private var preferredPlayer = "AVPlayer"
    @AppStorage("autoPlay") private var autoPlay = true

    var body: some View {
        Form {
            Section("Playback") {
                Picker("Preferred Player", selection: $preferredPlayer) {
                    Text("AVPlayer").tag("AVPlayer")
                    Text("VLC").tag("VLC")
                }
                Toggle("Auto-play next channel", isOn: $autoPlay)
            }
        }
        .navigationTitle("Player Settings")
    }
}
