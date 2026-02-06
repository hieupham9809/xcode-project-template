import CoreData
import CloudKit
import Foundation

public final class CoreDataStack: @unchecked Sendable {
    public enum StoreKind: Sendable {
        case persistent
        case inMemory
    }

    public enum CoreDataStackError: Error, Sendable, Equatable {
        case persistentStoreLoadFailed
        case cloudKitSyncEnableFailed
        case cloudKitSyncDisableFailed
    }

    public let container: NSPersistentCloudKitContainer
    private let isCloudKitEnabled: Bool

    public init(storeKind: StoreKind = .persistent, isCloudKitEnabled: Bool = false) throws {
        self.isCloudKitEnabled = isCloudKitEnabled
        let model = CoreDataModelFactory.makeModel()
        container = NSPersistentCloudKitContainer(name: "SmartSubscription", managedObjectModel: model)

        // Configure store descriptions based on storeKind and CloudKit status
        var descriptions: [NSPersistentStoreDescription] = []

        switch storeKind {
        case .inMemory:
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            description.url = URL(fileURLWithPath: "/dev/null")
            descriptions.append(description)

        case .persistent:
            // Local SQLite store (always present)
            let localDescription = NSPersistentStoreDescription(url: Self.defaultStoreURL())
            localDescription.shouldMigrateStoreAutomatically = true
            localDescription.shouldInferMappingModelAutomatically = true
            localDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            localDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            descriptions.append(localDescription)

            // CloudKit store (only if enabled)
            if isCloudKitEnabled {
                let cloudDescription = NSPersistentStoreDescription(url: Self.cloudStoreURL())
                cloudDescription.shouldMigrateStoreAutomatically = true
                cloudDescription.shouldInferMappingModelAutomatically = true
                cloudDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
                cloudDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

                // Configure CloudKit container
                let containerIdentifier = "iCloud.com.devindi.SmartSubscription"
                cloudDescription.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
                    containerIdentifier: containerIdentifier
                )
                descriptions.append(cloudDescription)
            }
        }

        container.persistentStoreDescriptions = descriptions

        let semaphore = DispatchSemaphore(value: 0)
        var loadError: Error?
        container.loadPersistentStores { _, error in
            loadError = error
            semaphore.signal()
        }
        semaphore.wait()
        if loadError != nil {
            throw CoreDataStackError.persistentStoreLoadFailed
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    public func performBackground<T: Sendable>(
        _ work: @Sendable @escaping (NSManagedObjectContext) throws -> T
    ) async throws -> T {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return try await context.performAsync(work)
    }

    private static func defaultStoreURL() -> URL {
        let fileManager = FileManager.default
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? fileManager.temporaryDirectory
        let directory = base.appendingPathComponent("SmartSubscription", isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("SmartSubscription.sqlite")
    }

    private static func cloudStoreURL() -> URL {
        let fileManager = FileManager.default
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? fileManager.temporaryDirectory
        let directory = base.appendingPathComponent("SmartSubscription", isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("SmartSubscription_cloud.sqlite")
    }

    /// Enable CloudKit sync by adding the CloudKit store to the container
    /// This migrates existing local data to the CloudKit store
    public func enableCloudKitSync() async throws {
        // Create cloud store description
        let cloudDescription = NSPersistentStoreDescription(url: Self.cloudStoreURL())
        cloudDescription.shouldMigrateStoreAutomatically = true
        cloudDescription.shouldInferMappingModelAutomatically = true
        cloudDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        cloudDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        // Configure CloudKit container
        let containerIdentifier = "iCloud.com.devindi.SmartSubscription"
        cloudDescription.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
            containerIdentifier: containerIdentifier
        )

        // Add the cloud store to existing stores
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            container.persistentStoreCoordinator.addPersistentStore(with: cloudDescription) { _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    /// Disable CloudKit sync by removing the CloudKit store
    /// Local data remains intact in the SQLite store
    public func disableCloudKitSync() async throws {
        // Find and remove the CloudKit store
        let cloudURL = Self.cloudStoreURL()
        if let cloudStore = container.persistentStoreCoordinator.persistentStores.first(where: { $0.url == cloudURL }) {
            try container.persistentStoreCoordinator.remove(cloudStore)
        }
    }
}
