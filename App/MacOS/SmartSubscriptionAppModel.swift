//
//  SmartSubscriptionAppModel.swift
//  SmartSubscription
//
//  Created by Harley Pham on 3/11/24.
//

import SmartSubscriptionKit
import Foundation
import SwiftUI

final class SmartSubscriptionAppModel {
    static let shared = SmartSubscriptionAppModel()
    
#if APP_SANDBOX
    let isAppSandbox = true
#else
    let isAppSandbox = false
#endif

    private(set) var contentViewModel: ContentViewModel
    
    // Core Dependencies
    let coreDataStack: CoreDataStack
    let subscriptionRepository: SubscriptionRepository
    let invoiceRepository: InvoiceRepository
    let settingsStore: SettingsStore
    let keychainStore: KeychainStore
    
    // Use Cases
    let subscriptionUseCase: SubscriptionUseCase
    let invoiceOCRUseCase: InvoiceOCRUseCase

    private init() {
        // Initialize Settings Store first (needed for CloudKit setting)
        self.settingsStore = SettingsStore.shared
        self.keychainStore = KeychainStore(service: Bundle.main.bundleIdentifier ?? "SmartSubscription")

        // Initialize Core Data Stack with CloudKit setting
        let isCloudKitEnabled = settingsStore.isCloudKitSyncEnabled
        do {
            self.coreDataStack = try CoreDataStack(
                storeKind: .persistent,
                isCloudKitEnabled: isCloudKitEnabled
            )
        } catch {
            fatalError("Failed to initialize Core Data stack: \(error)")
        }

        self.subscriptionRepository = CoreDataSubscriptionRepository(stack: coreDataStack)
        self.invoiceRepository = CoreDataInvoiceRepository(stack: coreDataStack)

        // Initialize Use Cases
        self.subscriptionUseCase = AppSubscriptionUseCase(repository: subscriptionRepository)

        let session = URLSession(configuration: .default)
        let parser = OpenAIVisionParser(session: session, settingsStore: settingsStore)
        self.invoiceOCRUseCase = AppInvoiceOCRUseCase(parser: parser)

        contentViewModel = ContentViewModel()

        // Listen for CloudKit sync toggle notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCloudKitSyncToggle(_:)),
            name: .cloudKitSyncToggled,
            object: nil
        )
    }

    @objc private func handleCloudKitSyncToggle(_ notification: Notification) {
        guard let enabled = notification.userInfo?["enabled"] as? Bool else { return }

        Task {
            do {
                if enabled {
                    try await coreDataStack.enableCloudKitSync()
                    print("✅ CloudKit sync enabled successfully")
                } else {
                    try await coreDataStack.disableCloudKitSync()
                    print("✅ CloudKit sync disabled successfully")
                }
            } catch {
                print("❌ Failed to toggle CloudKit sync: \(error)")
                // Post error notification for UI to handle
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: .init("cloudKitSyncError"),
                        object: nil,
                        userInfo: ["error": error]
                    )
                }
            }
        }
    }
}

final class ContentViewModel {
    // For displayed view
}

final class ViewModelCaching<Value, Data> {
    let shouldReuse: (_ value: Value, _ data: Data) -> Bool
    let generate: (_ data: Data) -> Value?

    @MainActor
    init(
        shouldReuse: @escaping (_ value: Value, _ data: Data) -> Bool,
        generate: @escaping (_ data: Data) -> Value?
    ) {
        self.shouldReuse = shouldReuse
        self.generate = generate
    }

    @MainActor
    func get(with data: Data) -> Value? {
        if let value = value, shouldReuse(value, data) {
            return value
        }

        let newValue = generate(data)
        newValue.map { update($0) }
        return newValue
    }

    @MainActor
    private(set) var value: Value?

    @MainActor
    func update(_ value: Value) {
        self.value = value
    }
}
