import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Providers") {
                    NavigationLink("Manage Providers") {
                        ProviderListView()
                    }
                }

                Section("Player") {
                    NavigationLink("Player Settings") {
                        PlayerSettingsView()
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
