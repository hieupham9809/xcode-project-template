import Combine
import Foundation
import SmartSubscriptionKit

@MainActor
final class SubscriptionDetailViewModel: ObservableObject {
    @Published var subscription: SmartSubscriptionKit.Subscription
    @Published var invoices: [Invoice] = []
    @Published var isLoadingInvoices = false
    @Published var errorMessage: String?

    // For editing/deleting
    @Published var isDeleting = false
    @Published var shouldDismiss = false

    private let subscriptionUseCase: SubscriptionUseCase
    private let invoiceRepository: InvoiceRepository // Direct repo access or via UseCase if exists

    var subscriptionAmountFormatted: String {
        let formatter = Formatters.currencyFormatter(for: subscription.amount.currencyCode)
        return formatter.string(from: subscription.amount.amount as NSDecimalNumber) ?? "\(subscription.amount) \(subscription.amount.currencyCode)"
    }

    init(
        subscription: SmartSubscriptionKit.Subscription,
        subscriptionUseCase: SubscriptionUseCase,
        invoiceRepository: InvoiceRepository // We should probably expose this via a UseCase later
    ) {
        self.subscription = subscription
        self.subscriptionUseCase = subscriptionUseCase
        self.invoiceRepository = invoiceRepository
    }

    func loadInvoices() async {
        isLoadingInvoices = true
        do {
            invoices = try await invoiceRepository.fetchAll(for: subscription.id)
        } catch {
            print("[SubscriptionDetailVM] Failed to load invoices: \(error)")
        }
        isLoadingInvoices = false
    }

    func deleteSubscription() async {
        isDeleting = true
        do {
            try await subscriptionUseCase.deleteSubscription(id: subscription.id)
            shouldDismiss = true
        } catch {
            errorMessage = "Failed to delete: \(error.localizedDescription)"
        }
        isDeleting = false
    }
}
