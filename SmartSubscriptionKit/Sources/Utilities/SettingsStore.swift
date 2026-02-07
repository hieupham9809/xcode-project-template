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
        get {
            UserDefaults.standard.string(forKey: Keys.selectedModel) ?? "gpt-4o-mini"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.selectedModel)
        }
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
        get {
            if let rawValue = UserDefaults.standard.string(forKey: Keys.parserMode),
               let mode = ParserMode(rawValue: rawValue)
            {
                return mode
            }
            return .normal // Default to normal mode for backward compatibility
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: Keys.parserMode)
        }
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

    public func getOpenAIAPIKey() throws -> String? {
        let value = try keychain.getString(forKey: Keys.openAIAPIKey)
        if let value, value.isEmpty {
            return nil
        }
        return value
    }

    public func setOpenAIAPIKey(_ value: String?) throws {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let trimmed, !trimmed.isEmpty {
            try keychain.set(trimmed, forKey: Keys.openAIAPIKey)
        } else {
            try keychain.delete(forKey: Keys.openAIAPIKey)
        }
    }

    public var openAIAPIKey: String? {
        get {
            try? getOpenAIAPIKey()
        }
        set {
            try? setOpenAIAPIKey(newValue)
        }
    }
}
