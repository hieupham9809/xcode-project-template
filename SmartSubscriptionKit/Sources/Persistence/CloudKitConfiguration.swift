import CloudKit
import Foundation

public enum CloudKitConfiguration {
    /// CloudKit container identifier used for syncing
    public static let containerIdentifier = "iCloud.com.devindi.SmartSubscription"

    /// Check if CloudKit is available and user is signed into iCloud
    public static func isCloudKitAvailable() async -> Bool {
        let container = CKContainer(identifier: containerIdentifier)
        do {
            let status = try await container.accountStatus()
            return status == .available
        } catch {
            return false
        }
    }

    /// Get the current iCloud account status
    public static func checkAccountStatus() async throws -> CKAccountStatus {
        let container = CKContainer(identifier: containerIdentifier)
        return try await container.accountStatus()
    }
}
