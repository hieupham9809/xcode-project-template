import Foundation
import SmartSubscriptionKit
import Combine

@MainActor
final class HomeDashboardViewModel: ObservableObject {
    enum Period: String, CaseIterable, Identifiable {
        case monthly = "Monthly"
        case yearly = "Yearly"
        var id: String { rawValue }
    }

    @Published var subscriptions: [SmartSubscriptionKit.Subscription] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedPeriod: Period = .monthly

    private let subscriptionUseCase: SubscriptionUseCase

    init(subscriptionUseCase: SubscriptionUseCase) {
        self.subscriptionUseCase = subscriptionUseCase
    }

    var totalSpend: String {
        let total = subscriptions.reduce(Decimal.zero) { result, sub in
            guard sub.status == .active else { return result }
            return result + sub.normalizedAmount(for: selectedPeriod)
        }
        // Assuming single currency for MVP or user's local currency.
        // For now, let's just format it as currency (e.g. $)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = subscriptions.first?.amount.currencyCode ?? "USD"
        return formatter.string(from: total as NSDecimalNumber) ?? "$0.00"
    }

    var upcomingRenewals: [SmartSubscriptionKit.Subscription] {
        let calendar = Calendar.current
        let today = Date()
        let next7Days = calendar.date(byAdding: .day, value: 7, to: today)!
        
        return subscriptions.filter { sub in
            guard sub.status == .active, let nextDate = sub.nextBillingDate else { return false }
            return nextDate >= today && nextDate <= next7Days
        }.sorted { ($0.nextBillingDate ?? Date.distantFuture) < ($1.nextBillingDate ?? Date.distantFuture) }
    }

    var activeSubscriptions: [SmartSubscriptionKit.Subscription] {
        subscriptions.filter { $0.status == .active }
            .sorted { ($0.nextBillingDate ?? Date.distantFuture) < ($1.nextBillingDate ?? Date.distantFuture) }
    }

    func loadSubscriptions() async {
        isLoading = true
        errorMessage = nil
        do {
            subscriptions = try await subscriptionUseCase.getAllSubscriptions()
        } catch {
            errorMessage = "Failed to load subscriptions: \(error.localizedDescription)"
        }
        isLoading = false
    }

    func deleteSubscription(id: SmartSubscriptionKit.Subscription.ID) async {
        do {
            try await subscriptionUseCase.deleteSubscription(id: id)
            await loadSubscriptions()
        } catch {
            errorMessage = "Failed to delete subscription: \(error.localizedDescription)"
        }
    }
}

private extension SmartSubscriptionKit.Subscription {
    func normalizedAmount(for period: HomeDashboardViewModel.Period) -> Decimal {
        let amount = self.amount.amount
        switch (self.cadence, period) {
        case (.monthly, .monthly):
            return amount
        case (.monthly, .yearly):
            return amount * 12
        case (.yearly, .monthly):
            return amount / 12
        case (.yearly, .yearly):
            return amount
        case (.weekly, .monthly):
            return amount * 4.33 // Approx
        case (.weekly, .yearly):
            return amount * 52
        case (.customDays(let days), .monthly):
             return amount * (30.0 / Decimal(days))
        case (.customDays(let days), .yearly):
             return amount * (365.0 / Decimal(days))
        }
    }
}
