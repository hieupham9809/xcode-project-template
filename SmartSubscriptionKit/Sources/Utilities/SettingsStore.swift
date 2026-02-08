import Foundation

public struct SettingsStore: Sendable {
    public struct Keys: Sendable {
        public static let openAIAPIKey = "OpenAIAPIKey"
        public static let selectedModel = "SelectedOpenAIModel"
        public static let isCloudKitSyncEnabled = "IsCloudKitSyncEnabled"
        public static let parserMode = "ParserMode"
        public static let defaultCurrency = "DefaultCurrency"
    }

    public static let shared = SettingsStore()

    public var keychain: KeychainStore

    public init(service: String = Bundle.main.bundleIdentifier ?? "SmartSubscription") {
        keychain = KeychainStore(service: service)
    }

    public var selectedModel: String {
        AppConfiguration.openAIModel
    }

    public var isCloudKitSyncEnabled: Bool {
        get {
            UserDefaults.standard.bool(forKey: Keys.isCloudKitSyncEnabled)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.isCloudKitSyncEnabled)
        }
    }

    public var parserMode: ParserMode {
        .optimizing
    }

    /// User's preferred currency for displaying subscription costs and statistics.
    /// Defaults to the system locale currency, or USD if not available.
    public var defaultCurrency: String {
        get {
            UserDefaults.standard.string(forKey: Keys.defaultCurrency)
                ?? Locale.current.currency?.identifier
                ?? "USD"
        }
        set {
            UserDefaults.standard.set(newValue.uppercased(), forKey: Keys.defaultCurrency)
        }
    }

    public var openAIAPIKey: String? {
        // Return the hardcoded key from AppConfiguration
        let key = AppConfiguration.openAIAPIKey
        return key.isEmpty ? nil : key
    }
}
