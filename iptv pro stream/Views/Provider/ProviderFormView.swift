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
        #if os(tvOS)
        tvOSBody
        #else
        defaultBody
        #endif
    }

    #if os(tvOS)
    @State private var activeField: TVField?

    private enum TVField: String, Identifiable {
        case name, m3uURL, epgURL, xtreamHost, xtreamUsername, xtreamPassword
        var id: String { rawValue }

        var title: String {
            switch self {
            case .name: "Name"
            case .m3uURL: "Playlist URL"
            case .epgURL: "EPG URL (optional)"
            case .xtreamHost: "Server URL"
            case .xtreamUsername: "Username"
            case .xtreamPassword: "Password"
            }
        }
    }

    private var tvOSBody: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                Text("Add Provider")
                    .font(.title2.bold())

                VStack(alignment: .leading, spacing: 12) {
                    Text("PROVIDER INFO")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    tvFieldButton(.name, value: name)
                    Picker("Type", selection: $providerType) {
                        Text("M3U Playlist").tag(ProviderType.m3u)
                        Text("Xtream Codes").tag(ProviderType.xtreamCodes)
                    }
                }

                if providerType == .m3u {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("M3U SETTINGS")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        tvFieldButton(.m3uURL, value: m3uURL)
                        tvFieldButton(.epgURL, value: epgURL)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("XTREAM CODES SETTINGS")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        tvFieldButton(.xtreamHost, value: xtreamHost)
                        tvFieldButton(.xtreamUsername, value: xtreamUsername)
                        tvFieldButton(.xtreamPassword, value: xtreamPassword, isSecure: true)
                    }
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }

                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    Spacer()
                    Button("Save") {
                        save()
                    }
                    .disabled(!isValid || isSaving)
                }
                .padding(.top, 10)
            }
            .padding(60)
        }
        .fullScreenCover(item: $activeField) { field in
            TVKeyboardInput(
                title: field.title,
                text: bindingForField(field),
                isSecure: field == .xtreamPassword
            ) {
                activeField = nil
            }
        }
    }

    private func tvFieldButton(_ field: TVField, value: String, isSecure: Bool = false) -> some View {
        Button {
            activeField = field
        } label: {
            HStack {
                Text(field.title)
                    .foregroundStyle(.secondary)
                Spacer()
                if value.isEmpty {
                    Text("Not Set")
                        .foregroundStyle(.tertiary)
                } else if isSecure {
                    Text(String(repeating: "•", count: value.count))
                } else {
                    Text(value)
                        .lineLimit(1)
                }
            }
        }
    }

    private func bindingForField(_ field: TVField?) -> Binding<String> {
        switch field {
        case .name: $name
        case .m3uURL: $m3uURL
        case .epgURL: $epgURL
        case .xtreamHost: $xtreamHost
        case .xtreamUsername: $xtreamUsername
        case .xtreamPassword: $xtreamPassword
        case nil: .constant("")
        }
    }
    #endif

    private var defaultBody: some View {
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

#if os(tvOS)
import UIKit

private struct TVKeyboardInput: UIViewControllerRepresentable {
    let title: String
    @Binding var text: String
    var isSecure: Bool = false
    let onDismiss: () -> Void

    func makeUIViewController(context: Context) -> TVKeyboardInputController {
        let controller = TVKeyboardInputController()
        controller.fieldTitle = title
        controller.initialText = text
        controller.isSecure = isSecure
        controller.onComplete = { newText in
            text = newText
            onDismiss()
        }
        controller.onCancel = {
            onDismiss()
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: TVKeyboardInputController, context: Context) {}
}

private class TVKeyboardInputController: UIViewController, UITextFieldDelegate {
    var fieldTitle = ""
    var initialText = ""
    var isSecure = false
    var onComplete: ((String) -> Void)?
    var onCancel: (() -> Void)?

    private let textField = UITextField()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        textField.text = initialText
        textField.placeholder = fieldTitle
        textField.isSecureTextEntry = isSecure
        textField.delegate = self
        textField.borderStyle = .none
        // Hidden off-screen — we only need it to trigger the keyboard
        textField.frame = CGRect(x: -1000, y: -1000, width: 100, height: 44)
        view.addSubview(textField)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textField.becomeFirstResponder()
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        onComplete?(textField.text ?? "")
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
#endif
