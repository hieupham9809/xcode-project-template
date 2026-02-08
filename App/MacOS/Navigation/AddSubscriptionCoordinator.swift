import Foundation
import SmartSubscriptionKit
import SwiftUI

public enum NavigationRoute: Hashable, Sendable {
    case addSubscription
    case subscriptionDetail(SmartSubscriptionKit.Subscription.ID)
    case editSubscription(SmartSubscriptionKit.Subscription.ID)
    case settings
    case ocrProcessing(URL)
    case reviewSubscription(Invoice?)
    case analytics
    case categoryManagement
}

public protocol AddSubscriptionCoordinator: Sendable {
    @MainActor func start()
    @MainActor func dismiss()
}

public final class AppAddSubscriptionCoordinator: AddSubscriptionCoordinator, ObservableObject {
    @Binding var path: NavigationPath
    private let invoiceOCRUseCase: InvoiceOCRUseCase
    private let subscriptionUseCase: SubscriptionUseCase

    public init(
        path: Binding<NavigationPath>,
        invoiceOCRUseCase: InvoiceOCRUseCase,
        subscriptionUseCase: SubscriptionUseCase
    ) {
        self._path = path
        self.invoiceOCRUseCase = invoiceOCRUseCase
        self.subscriptionUseCase = subscriptionUseCase
    }

    @MainActor
    public func start() {
        path.append(NavigationRoute.addSubscription)
    }

    @MainActor
    public func dismiss() {
        if !path.isEmpty {
            path.removeLast()
        }
    }
}
