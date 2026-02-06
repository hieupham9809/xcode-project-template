import Foundation

public struct SettingsStore: Sendable {
    public struct Keys: Sendable {
        public static let openAIAPIKey = "OpenAIAPIKey"
        public static let selectedModel = "SelectedOpenAIModel"
        public static let isCloudKitSyncEnabled = "IsCloudKitSyncEnabled"
    }

    public static let shared = SettingsStore()

    public var keychain: KeychainStore

    public init(service: String = Bundle.main.bundleIdentifier ?? "SmartSubscription") {
        self.keychain = KeychainStore(service: service)
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
