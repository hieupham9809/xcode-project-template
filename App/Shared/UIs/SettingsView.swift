import SmartSubscriptionKit
import SwiftUI
#if os(iOS)
    import UIKit
#endif

struct SettingsView: View {
    @StateObject var viewModel = SettingsViewModel()
    @Binding var path: NavigationPath
    @Environment(\.dismiss) private var dismiss

    // FocusState removed as API Key field is gone

    @MainActor
    init(viewModel: SettingsViewModel? = nil, path: Binding<NavigationPath>) {
        _viewModel = StateObject(wrappedValue: viewModel ?? SettingsViewModel())
        _path = path
    }

    var body: some View {
        Form {
            // AI Configuration and Invoice Parsing are now handled automatically
            // and hidden from the user.

            Section(header: Text("Appearance")) {
                Picker("Theme", selection: $viewModel.appearanceMode) {
                    ForEach(AppearanceMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .onChange(of: viewModel.appearanceMode) { newValue in
                    viewModel.updateAppearanceMode(newValue)
                }
            }

            Section {
                Picker("Default Currency", selection: $viewModel.defaultCurrency) {
                    ForEach(viewModel.supportedCurrencies) { currency in
                        Text("\(currency.symbol) \(currency.code) - \(currency.name)")
                            .tag(currency.code)
                    }
                }
                .onChange(of: viewModel.defaultCurrency) { newValue in
                    viewModel.updateDefaultCurrency(newValue)
                }

                HStack {
                    Button {
                        Task {
                            await viewModel.updateExchangeRates()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Update Exchange Rates")
                        }
                    }
                    .disabled(viewModel.isUpdatingRates)

                    Spacer()

                    if viewModel.isUpdatingRates {
                        ProgressView()
                            .scaleEffect(0.7)
                    }
                }

                if let lastUpdate = viewModel.lastRatesUpdate {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.secondary)
                            .font(.caption)
                        Text("Last updated: \(lastUpdate, style: .relative)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("Currency")
            } footer: {
                Text("All subscription amounts will be converted to your default currency for statistics. Exchange rates are fetched from an online source.")
                    .font(.caption)
            }

            Section(header: Text("Organization")) {
                NavigationLink(value: NavigationRoute.categoryManagement) {
                    Text("Manage Categories")
                }
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
                        dismiss()
                    }
                    #if os(iOS)
                    .fontWeight(.semibold)
                    #endif
                }
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
