import Foundation

/// Errors that can occur during CloudKit sync operations
public enum CloudKitSyncError: Error, LocalizedError {
    case accountNotAvailable
    case networkUnavailable
    case quotaExceeded
    case syncFailed(Error)

    public var errorDescription: String? {
        switch self {
        case .accountNotAvailable:
            return "iCloud account is not available. Please sign in to iCloud in System Settings."
        case .networkUnavailable:
            return "Network is unavailable. CloudKit sync will resume when online."
        case .quotaExceeded:
            return "iCloud storage quota exceeded. Please free up space or upgrade your iCloud storage plan."
        case .syncFailed(let error):
            return "Sync failed: \(error.localizedDescription)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .accountNotAvailable:
            return "Open System Settings and sign in to iCloud."
        case .networkUnavailable:
            return "Check your internet connection and try again."
        case .quotaExceeded:
            return "Free up space in iCloud or upgrade your storage plan."
        case .syncFailed:
            return "Try again later. If the problem persists, contact support."
        }
    }
}
