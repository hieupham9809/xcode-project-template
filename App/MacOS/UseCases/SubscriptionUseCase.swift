import Foundation
import SmartSubscriptionKit

public protocol SubscriptionUseCase: Sendable {
    func getAllSubscriptions() async throws -> [SmartSubscriptionKit.Subscription]
    func addSubscription(_ subscription: SmartSubscriptionKit.Subscription) async throws
    func deleteSubscription(id: SmartSubscriptionKit.Subscription.ID) async throws
    func updateSubscription(_ subscription: SmartSubscriptionKit.Subscription) async throws
}

public actor AppSubscriptionUseCase: SubscriptionUseCase {
    private let repository: SubscriptionRepository

    public init(repository: SubscriptionRepository) {
        self.repository = repository
    }

    public func getAllSubscriptions() async throws -> [SmartSubscriptionKit.Subscription] {
        try await repository.fetchAll()
    }

    public func addSubscription(_ subscription: SmartSubscriptionKit.Subscription) async throws {
        try await repository.save(subscription)
    }

    public func deleteSubscription(id: SmartSubscriptionKit.Subscription.ID) async throws {
        try await repository.delete(id: id)
    }

    public func updateSubscription(_ subscription: SmartSubscriptionKit.Subscription) async throws {
        try await repository.save(subscription)
    }
}
