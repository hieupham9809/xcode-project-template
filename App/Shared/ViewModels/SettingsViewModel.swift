import CloudKit
import Combine
import Foundation
import SmartSubscriptionKit

extension Notification.Name {
    static let cloudKitSyncToggled = Notification.Name("cloudKitSyncToggled")
    static let defaultCurrencyChanged = Notification.Name("defaultCurrencyChanged")
}

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var selectedModel: String = AppConfiguration.openAIModel
    @Published var parserMode: ParserMode = .optimizing
    @Published var isCloudKitSyncEnabled: Bool = false
    @Published var lastSyncDate: Date?

    // UI State
    @Published var isSecuredAPIKeyVisible: Bool = false
    @Published var errorMessage: String?
    @Published var isCheckingCloudKit: Bool = false

    // Export
    @Published var exportedFileURL: URL?
    @Published var isShowingShareSheet: Bool = false

    // Currency Settings
    @Published var defaultCurrency: String = "USD"
    @Published var isUpdatingRates: Bool = false
    @Published var lastRatesUpdate: Date?
    @Published var supportedCurrencies: [CurrencyInfo] = CurrencyInfo.commonCurrencies

    // Appearance Settings
    @Published var appearanceMode: AppearanceMode = .system

    private var settingsStore: SettingsStore
    private var subscriptionUseCase: SubscriptionUseCase?
    private let currencyConverter: CurrencyConverter

    init(
        settingsStore: SettingsStore = .shared,
        subscriptionUseCase: SubscriptionUseCase? = nil,
        currencyConverter: CurrencyConverter = CurrencyConverter()
    ) {
        self.settingsStore = settingsStore
        self.subscriptionUseCase = subscriptionUseCase
        self.currencyConverter = currencyConverter
        loadSettings()
    }

    func loadSettings() {
        selectedModel = settingsStore.selectedModel
        parserMode = settingsStore.parserMode
        isCloudKitSyncEnabled = settingsStore.isCloudKitSyncEnabled
        defaultCurrency = settingsStore.defaultCurrency
        appearanceMode = settingsStore.appearanceMode

        // Load cached exchange rates info
        Task {
            if let rates = await currencyConverter.exchangeRates {
                await MainActor.run {
                    self.lastRatesUpdate = rates.lastUpdated
                }
            }
        }
    }

    // AI Configuration methods removed as they are now hardcoded

    // MARK: - Appearance Management

    func updateAppearanceMode(_ mode: AppearanceMode) {
        appearanceMode = mode
        settingsStore.appearanceMode = mode
    }

    // MARK: - Currency Management

    func updateDefaultCurrency(_ currency: String) {
        defaultCurrency = currency
        settingsStore.defaultCurrency = currency

        // Notify other view models to recalculate with new currency
        NotificationCenter.default.post(
            name: .defaultCurrencyChanged,
            object: nil,
            userInfo: ["currency": currency]
        )
    }

    func updateExchangeRates() async {
        isUpdatingRates = true
        defer { isUpdatingRates = false }

        do {
            try await currencyConverter.refreshRates()
            if let rates = await currencyConverter.exchangeRates {
                lastRatesUpdate = rates.lastUpdated
            }
        } catch {
            errorMessage = "Failed to update exchange rates: \(error.localizedDescription)"
        }
    }

    // MARK: - CloudKit Sync

    func toggleCloudKitSync(_ isEnabled: Bool) async {
        isCheckingCloudKit = true
        defer { isCheckingCloudKit = false }

        // If disabling, just update the setting and notify
        if !isEnabled {
            isCloudKitSyncEnabled = false
            settingsStore.isCloudKitSyncEnabled = false
            NotificationCenter.default.post(
                name: .cloudKitSyncToggled,
                object: nil,
                userInfo: ["enabled": false]
            )
            return
        }

        // If enabling, check CloudKit availability first
        let isAvailable = await CloudKitConfiguration.isCloudKitAvailable()
        guard isAvailable else {
            errorMessage = "iCloud is not available. Please sign in to iCloud in System Settings."
            isCloudKitSyncEnabled = false
            return
        }

        // Check account status
        do {
            let status = try await CloudKitConfiguration.checkAccountStatus()
            guard status == .available else {
                errorMessage = "iCloud account is not available (\(accountStatusDescription(status)))."
                isCloudKitSyncEnabled = false
                return
            }
        } catch {
            errorMessage = "Failed to check iCloud status: \(error.localizedDescription)"
            isCloudKitSyncEnabled = false
            return
        }

        // All checks passed, enable sync
        isCloudKitSyncEnabled = true
        settingsStore.isCloudKitSyncEnabled = true
        lastSyncDate = Date()

        // Notify the app model to enable CloudKit sync
        NotificationCenter.default.post(
            name: .cloudKitSyncToggled,
            object: nil,
            userInfo: ["enabled": true]
        )
    }

    private func accountStatusDescription(_ status: CKAccountStatus) -> String {
        switch status {
        case .couldNotDetermine:
            return "could not determine"
        case .available:
            return "available"
        case .restricted:
            return "restricted"
        case .noAccount:
            return "no account"
        case .temporarilyUnavailable:
            return "temporarily unavailable"
        @unknown default:
            return "unknown"
        }
    }

    func exportData() async {
        guard let useCase = subscriptionUseCase else {
            errorMessage = "Export unavailable"
            return
        }
        do {
            let subscriptions = try await useCase.getAllSubscriptions()
            exportCSV(subscriptions: subscriptions)
        } catch {
            errorMessage = "Failed to load subscriptions for export: \(error.localizedDescription)"
        }
    }

    func exportCSV(subscriptions: [SmartSubscriptionKit.Subscription]) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short

        var csv = "Name,Provider,Amount,Currency,Billing Cycle,Status,Start Date,Next Billing Date,Notes\n"
        for sub in subscriptions {
            let name = sub.name.escapedCSV
            let provider = (sub.providerName ?? "").escapedCSV
            let amount = "\(sub.amount.amount)"
            let currency = sub.amount.currencyCode
            let cadence = sub.cadence.csvDescription
            let status = sub.status.rawValue.capitalized
            let start = dateFormatter.string(from: sub.startDate)
            let nextBilling = sub.nextBillingDate.map { dateFormatter.string(from: $0) } ?? ""
            let notes = (sub.notes ?? "").escapedCSV

            csv += "\(name),\(provider),\(amount),\(currency),\(cadence),\(status),\(start),\(nextBilling),\(notes)\n"
        }

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("SmartSubscriptions_Export.csv")

        do {
            try csv.write(to: tempURL, atomically: true, encoding: .utf8)
            exportedFileURL = tempURL
            isShowingShareSheet = true
        } catch {
            errorMessage = "Failed to export data: \(error.localizedDescription)"
        }
    }
}

private extension String {
    var escapedCSV: String {
        if contains(",") || contains("\"") || contains("\n") {
            return "\"\(replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return self
    }
}

private extension SmartSubscriptionKit.Subscription.BillingCadence {
    var csvDescription: String {
        switch self {
        case .weekly: "Weekly"
        case .monthly: "Monthly"
        case .yearly: "Yearly"
        case let .customDays(days): "Every \(days) days"
        }
    }
}
