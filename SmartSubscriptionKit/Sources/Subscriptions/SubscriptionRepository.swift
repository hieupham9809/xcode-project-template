import CoreData
import Foundation

public enum SubscriptionRepositoryError: Error, Sendable, Equatable {
    case subscriptionNotFound
}

public protocol SubscriptionRepository: Sendable {
    func fetchAll() async throws -> [Subscription]
    func fetch(id: Subscription.ID) async throws -> Subscription?
    func save(_ subscription: Subscription) async throws
    func delete(id: Subscription.ID) async throws
    func fetchNextBilling(before date: Date) async throws -> [Subscription]
}

public actor CoreDataSubscriptionRepository: SubscriptionRepository {
    private let stack: CoreDataStack

    public init(stack: CoreDataStack) {
        self.stack = stack
    }

    public func fetchAll() async throws -> [Subscription] {
        try await stack.performBackground { context in
            let request = NSFetchRequest<SubscriptionEntity>(entityName: "SubscriptionEntity")
            request.sortDescriptors = [
                NSSortDescriptor(key: "updatedAt", ascending: false),
                NSSortDescriptor(key: "createdAt", ascending: false)
            ]
            return try context.fetch(request).map { $0.toDomain() }
        }
    }

    public func fetch(id: Subscription.ID) async throws -> Subscription? {
        try await stack.performBackground { context in
            let request = NSFetchRequest<SubscriptionEntity>(entityName: "SubscriptionEntity")
            request.fetchLimit = 1
            request.predicate = NSPredicate(format: "id == %@", id.rawValue as CVarArg)
            return try context.fetch(request).first?.toDomain()
        }
    }

    public func save(_ subscription: Subscription) async throws {
        try await stack.performBackground { context in
            let entity = try findOrCreateEntity(for: subscription.id, in: context)

            if let categoryID = subscription.categoryID {
                let categoryRequest = NSFetchRequest<CategoryEntity>(entityName: "CategoryEntity")
                categoryRequest.predicate = NSPredicate(format: "id == %@", categoryID.rawValue as CVarArg)
                entity.category = try context.fetch(categoryRequest).first
            } else {
                entity.category = nil
            }

            entity.apply(subscription)

            if context.hasChanges {
                try context.save()
            }
        }
    }

    public func delete(id: Subscription.ID) async throws {
        try await stack.performBackground { context in
            let request = NSFetchRequest<SubscriptionEntity>(entityName: "SubscriptionEntity")
            request.fetchLimit = 1
            request.predicate = NSPredicate(format: "id == %@", id.rawValue as CVarArg)
            guard let entity = try context.fetch(request).first else {
                throw SubscriptionRepositoryError.subscriptionNotFound
            }
            context.delete(entity)
            if context.hasChanges {
                try context.save()
            }
        }
    }

    public func fetchNextBilling(before date: Date) async throws -> [Subscription] {
        try await stack.performBackground { context in
            let request = NSFetchRequest<SubscriptionEntity>(entityName: "SubscriptionEntity")
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "nextBillingDate != nil"),
                NSPredicate(format: "nextBillingDate <= %@", date as NSDate),
                NSPredicate(format: "status == %@", Subscription.Status.active.rawValue)
            ])
            request.sortDescriptors = [
                NSSortDescriptor(key: "nextBillingDate", ascending: true)
            ]
            return try context.fetch(request).map { $0.toDomain() }
        }
    }
}

private func findOrCreateEntity(for id: Subscription.ID, in context: NSManagedObjectContext) throws -> SubscriptionEntity {
    let request = NSFetchRequest<SubscriptionEntity>(entityName: "SubscriptionEntity")
    request.fetchLimit = 1
    request.predicate = NSPredicate(format: "id == %@", id.rawValue as CVarArg)
    if let existing = try context.fetch(request).first {
        return existing
    }

    let entityDescription = NSEntityDescription.entity(forEntityName: "SubscriptionEntity", in: context)
    let entity = SubscriptionEntity(entity: entityDescription!, insertInto: context)
    entity.id = id.rawValue
    entity.createdAt = Date()
    entity.updatedAt = Date()
    return entity
}

private extension SubscriptionEntity {
    func apply(_ value: Subscription) {
        id = value.id.rawValue
        name = value.name
        providerName = value.providerName
        amount = NSDecimalNumber(decimal: value.amount.amount)
        currencyCode = value.amount.currencyCode

        switch value.cadence {
        case .weekly:
            cadenceKind = "weekly"
            cadenceCustomDays = 0
        case .monthly:
            cadenceKind = "monthly"
            cadenceCustomDays = 0
        case .yearly:
            cadenceKind = "yearly"
            cadenceCustomDays = 0
        case let .customDays(days):
            cadenceKind = "customDays"
            cadenceCustomDays = Int64(days)
        }

        startDate = value.startDate
        nextBillingDate = value.nextBillingDate
        status = value.status.rawValue
        notes = value.notes
        createdAt = value.createdAt
        updatedAt = value.updatedAt
    }

    func toDomain() -> Subscription {
        let cadence: Subscription.BillingCadence
        switch cadenceKind {
        case "weekly":
            cadence = .weekly
        case "monthly":
            cadence = .monthly
        case "yearly":
            cadence = .yearly
        case "customDays":
            cadence = .customDays(Int(cadenceCustomDays))
        default:
            cadence = .monthly
        }

        return Subscription(
            id: .init(rawValue: id),
            name: name,
            providerName: providerName,
            amount: Money(amount: amount.decimalValue, currencyCode: currencyCode),
            cadence: cadence,
            startDate: startDate,
            categoryID: category.map { SubscriptionCategory.ID(rawValue: $0.id) },
            nextBillingDate: nextBillingDate,
            status: Subscription.Status(rawValue: status) ?? .active,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

