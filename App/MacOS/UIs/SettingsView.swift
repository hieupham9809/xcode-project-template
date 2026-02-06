import SwiftUI
import SmartSubscriptionKit
#if os(iOS)
import UIKit
#endif

struct SettingsView: View {
    @StateObject var viewModel = SettingsViewModel()
    @Binding var path: NavigationPath
    @Environment(\.dismiss) private var dismiss

    #if os(iOS)
    @FocusState private var isAPIKeyFocused: Bool
    #endif

    @MainActor
    init(viewModel: SettingsViewModel? = nil, path: Binding<NavigationPath>) {
        _viewModel = StateObject(wrappedValue: viewModel ?? SettingsViewModel())
        _path = path
    }

    var body: some View {
        Form {
            Section {
                SecureField("OpenAI API Key", text: $viewModel.apiKey)
                    .onSubmit {
                        viewModel.saveAPIKey()
                    }
                    #if os(iOS)
                    .focused($isAPIKeyFocused)
                    .textContentType(.password)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    #endif

                #if os(iOS)
                if !viewModel.apiKey.isEmpty {
                    Text("API Key: \u{2022}\u{2022}\u{2022}\u{2022}\u{2022}\(String(viewModel.apiKey.suffix(4)))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                #endif

                Picker("OCR Model", selection: $viewModel.selectedModel) {
                    Text("GPT-4o Mini (Faster)").tag("gpt-4o-mini")
                    Text("GPT-4o (More Accurate)").tag("gpt-4o")
                }
                .onChange(of: viewModel.selectedModel) { newValue in
                    viewModel.updateModel(newValue)
                }
            } header: {
                Text("AI Configuration")
            } footer: {
                #if os(iOS)
                Text("Your API key is stored securely in the iOS Keychain.")
                    .font(.caption)
                #else
                EmptyView()
                #endif
            }

            Section {
                Toggle("iCloud Sync", isOn: $viewModel.isCloudKitSyncEnabled)
                    .onChange(of: viewModel.isCloudKitSyncEnabled) { newValue in
                        Task {
                            await viewModel.toggleCloudKitSync(newValue)
                        }
                    }
                    .disabled(viewModel.isCheckingCloudKit)

                // Show sync status when enabled
                if viewModel.isCloudKitSyncEnabled {
                    HStack {
                        Image(systemName: "cloud")
                            .foregroundColor(.secondary)
                        if viewModel.isCheckingCloudKit {
                            Text("Checking...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Text("Synced")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                        }
                        Spacer()
                    }

                    // Show last sync time if available
                    if let lastSync = viewModel.lastSyncDate {
                        Text("Last synced: \(lastSync, style: .relative)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Button("Export Data (CSV)") {
                    Task {
                        await viewModel.exportData()
                    }
                }
            } header: {
                Text("Data")
            } footer: {
                #if os(iOS)
                Text("Sync your subscriptions across all your devices using iCloud.")
                    .font(.caption)
                #else
                EmptyView()
                #endif
            }

            Section(header: Text("About")) {
                LabeledContent("Version", value: "1.0.0 (1)")

                #if os(iOS)
                Link(destination: URL(string: "https://example.com/privacy")!) {
                    HStack {
                        Text("Privacy Policy")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                #else
                Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                #endif
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    viewModel.saveAPIKey()
                    dismiss()
                }
                #if os(iOS)
                .fontWeight(.semibold)
                #endif
            }
            #if os(iOS)
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isAPIKeyFocused = false
                }
            }
            #endif
        }
        #if os(iOS)
        .sheet(isPresented: $viewModel.isShowingShareSheet) {
            if let url = viewModel.exportedFileURL {
                ShareSheet(items: [url])
                    .presentationDetents([.medium, .large])
            }
        }
        #endif
    }
}

#if os(iOS)
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif
