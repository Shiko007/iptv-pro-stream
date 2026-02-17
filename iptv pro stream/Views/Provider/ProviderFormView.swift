import SwiftUI

struct ProviderFormView: View {
    let onSave: (Provider) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var providerType: ProviderType = .m3u
    @State private var m3uURL = ""
    @State private var epgURL = ""
    @State private var xtreamHost = ""
    @State private var xtreamUsername = ""
    @State private var xtreamPassword = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Provider Info") {
                    TextField("Name", text: $name)
                    Picker("Type", selection: $providerType) {
                        Text("M3U Playlist").tag(ProviderType.m3u)
                        Text("Xtream Codes").tag(ProviderType.xtreamCodes)
                    }
                }

                if providerType == .m3u {
                    Section("M3U Settings") {
                        TextField("Playlist URL", text: $m3uURL)
                            #if os(iOS)
                            .textContentType(.URL)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            #endif
                        TextField("EPG URL (optional)", text: $epgURL)
                            #if os(iOS)
                            .textContentType(.URL)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            #endif
                    }
                } else {
                    Section("Xtream Codes Settings") {
                        TextField("Server URL (e.g. http://example.com:8080)", text: $xtreamHost)
                            #if os(iOS)
                            .textContentType(.URL)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            #endif
                        TextField("Username", text: $xtreamUsername)
                            #if os(iOS)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            #endif
                        SecureField("Password", text: $xtreamPassword)
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Add Provider")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(!isValid || isSaving)
                }
            }
        }
    }

    private var isValid: Bool {
        guard !name.trimmed.isEmpty else { return false }
        if providerType == .m3u {
            return m3uURL.trimmed.isValidURL
        } else {
            return !xtreamHost.trimmed.isEmpty && !xtreamUsername.trimmed.isEmpty && !xtreamPassword.trimmed.isEmpty
        }
    }

    private func save() {
        isSaving = true
        errorMessage = nil

        var provider: Provider
        if providerType == .m3u {
            let config = M3UConfig(url: m3uURL.trimmed, epgURL: epgURL.trimmed.isEmpty ? nil : epgURL.trimmed)
            provider = Provider(name: name.trimmed, type: .m3u, m3uConfig: config)
        } else {
            let config = XtreamConfig(host: xtreamHost.trimmed, username: xtreamUsername.trimmed, password: xtreamPassword.trimmed)
            provider = Provider(name: name.trimmed, type: .xtreamCodes, xtreamConfig: config)
        }

        onSave(provider)
        dismiss()
    }
}
