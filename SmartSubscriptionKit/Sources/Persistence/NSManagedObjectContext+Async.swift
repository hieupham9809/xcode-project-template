import CoreData

extension NSManagedObjectContext {
    func performAsync<T: Sendable>(
        _ block: @Sendable @escaping (NSManagedObjectContext) throws -> T
    ) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            perform {
                do {
                    continuation.resume(returning: try block(self))
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

