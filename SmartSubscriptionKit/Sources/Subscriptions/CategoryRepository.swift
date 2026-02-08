import CoreData
import Foundation

public enum CategoryRepositoryError: Error, Sendable {
    case notFound
}

public protocol CategoryRepository: Sendable {
    func fetchAll() async throws -> [SubscriptionCategory]
    func fetch(id: SubscriptionCategory.ID) async throws -> SubscriptionCategory?
    func save(_ category: SubscriptionCategory) async throws
    func delete(id: SubscriptionCategory.ID) async throws
    func seedDefaultCategoriesIfNeeded() async throws
}

public actor CoreDataCategoryRepository: CategoryRepository {
    private let stack: CoreDataStack

    public init(stack: CoreDataStack) {
        self.stack = stack
    }

    public func fetchAll() async throws -> [SubscriptionCategory] {
        try await stack.performBackground { context in
            let request = NSFetchRequest<CategoryEntity>(entityName: "CategoryEntity")
            request.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]
            let entities = try context.fetch(request)
            return entities.map { $0.toDomain() }
        }
    }

    public func fetch(id: SubscriptionCategory.ID) async throws -> SubscriptionCategory? {
        try await stack.performBackground { context in
            let request = NSFetchRequest<CategoryEntity>(entityName: "CategoryEntity")
            request.predicate = NSPredicate(format: "id == %@", id.rawValue as CVarArg)
            request.fetchLimit = 1
            return try context.fetch(request).first?.toDomain()
        }
    }

    public func save(_ category: SubscriptionCategory) async throws {
        try await stack.performBackground { context in
            let entity = findOrCreateEntity(for: category.id, in: context)
            entity.apply(category)
            if context.hasChanges {
                try context.save()
            }
        }
    }

    public func delete(id: SubscriptionCategory.ID) async throws {
        try await stack.performBackground { context in
            let request = NSFetchRequest<CategoryEntity>(entityName: "CategoryEntity")
            request.predicate = NSPredicate(format: "id == %@", id.rawValue as CVarArg)
            if let entity = try context.fetch(request).first {
                context.delete(entity)
                if context.hasChanges {
                    try context.save()
                }
            }
        }
    }

    public func seedDefaultCategoriesIfNeeded() async throws {
        let existing = try await fetchAll()
        guard existing.isEmpty else { return }

        for category in SubscriptionCategory.defaultCategories {
            try await save(category)
        }
    }

}

private func findOrCreateEntity(for id: SubscriptionCategory.ID, in context: NSManagedObjectContext) -> CategoryEntity {
    let request = NSFetchRequest<CategoryEntity>(entityName: "CategoryEntity")
    request.predicate = NSPredicate(format: "id == %@", id.rawValue as CVarArg)
    request.fetchLimit = 1
    if let existing = try? context.fetch(request).first {
        return existing
    }
    let entity = CategoryEntity(context: context)
    entity.id = id.rawValue
    return entity
}

// MARK: - Entity Extensions

extension CategoryEntity {
    func apply(_ category: SubscriptionCategory) {
        id = category.id.rawValue
        name = category.name
        colorHex = category.colorHex
        iconName = category.iconName
        sortOrder = Int64(category.sortOrder)
        createdAt = category.createdAt
        updatedAt = category.updatedAt
    }

    func toDomain() -> SubscriptionCategory {
        SubscriptionCategory(
            id: SubscriptionCategory.ID(rawValue: id),
            name: name,
            colorHex: colorHex,
            iconName: iconName,
            sortOrder: Int(sortOrder),
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
