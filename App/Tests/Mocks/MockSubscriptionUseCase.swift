import Foundation
import SmartSubscriptionKit

final class MockSubscriptionUseCase: SubscriptionUseCase, @unchecked Sendable {
    var subscriptions: [SmartSubscriptionKit.Subscription] = []
    
    var fetchCalled = false
    var addCalled = false
    var deleteCalled = false
    var updateCalled = false
    
    var errorToThrow: Error?

    func getAllSubscriptions() async throws -> [SmartSubscriptionKit.Subscription] {
        fetchCalled = true
        if let error = errorToThrow {
            throw error
        }
        return subscriptions
    }

    func addSubscription(_ subscription: SmartSubscriptionKit.Subscription) async throws {
        addCalled = true
        if let error = errorToThrow {
            throw error
        }
        subscriptions.append(subscription)
    }

    func deleteSubscription(id: SmartSubscriptionKit.Subscription.ID) async throws {
        deleteCalled = true
        if let error = errorToThrow {
            throw error
        }
        subscriptions.removeAll { $0.id == id }
    }

    func updateSubscription(_ subscription: SmartSubscriptionKit.Subscription) async throws {
        updateCalled = true
        if let error = errorToThrow {
            throw error
        }
        if let index = subscriptions.firstIndex(where: { $0.id == subscription.id }) {
            subscriptions[index] = subscription
        }
    }
}
