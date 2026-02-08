import Foundation
import SmartSubscriptionKit

public protocol CategoryUseCase: Sendable {
    func getAllCategories() async throws -> [SubscriptionCategory]
    func addCategory(_ category: SubscriptionCategory) async throws
    func updateCategory(_ category: SubscriptionCategory) async throws
    func deleteCategory(id: SubscriptionCategory.ID) async throws
    func assignCategory(_ categoryID: SubscriptionCategory.ID?, to subscriptionID: Subscription.ID) async throws
    func getSubscriptions(for categoryID: SubscriptionCategory.ID) async throws -> [Subscription]
    func seedDefaultCategoriesIfNeeded() async throws
}

public actor DefaultCategoryUseCase: CategoryUseCase {
    private let categoryRepository: CategoryRepository
    private let subscriptionRepository: SubscriptionRepository

    public init(
        categoryRepository: CategoryRepository,
        subscriptionRepository: SubscriptionRepository
    ) {
        self.categoryRepository = categoryRepository
        self.subscriptionRepository = subscriptionRepository
    }

    public func getAllCategories() async throws -> [SubscriptionCategory] {
        let categories = try await categoryRepository.fetchAll()
        if categories.isEmpty {
            try await categoryRepository.seedDefaultCategoriesIfNeeded()
            return try await categoryRepository.fetchAll()
        }
        return categories
    }

    public func addCategory(_ category: SubscriptionCategory) async throws {
        try await categoryRepository.save(category)
    }

    public func updateCategory(_ category: SubscriptionCategory) async throws {
        var updated = category
        updated.updatedAt = Date()
        try await categoryRepository.save(updated)
    }

    public func deleteCategory(id: SubscriptionCategory.ID) async throws {
        try await categoryRepository.delete(id: id)
    }

    public func assignCategory(_ categoryID: SubscriptionCategory.ID?, to subscriptionID: Subscription.ID) async throws {
        guard var subscription = try await subscriptionRepository.fetch(id: subscriptionID) else {
            throw SubscriptionRepositoryError.subscriptionNotFound
        }
        subscription.categoryID = categoryID
        subscription.updatedAt = Date()
        try await subscriptionRepository.save(subscription)
    }

    public func getSubscriptions(for categoryID: SubscriptionCategory.ID) async throws -> [Subscription] {
        let all = try await subscriptionRepository.fetchAll()
        return all.filter { $0.categoryID == categoryID }
    }

    public func seedDefaultCategoriesIfNeeded() async throws {
        try await categoryRepository.seedDefaultCategoriesIfNeeded()
    }
}
