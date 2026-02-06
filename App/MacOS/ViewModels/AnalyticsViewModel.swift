import Foundation
import SmartSubscriptionKit
import Combine

@MainActor
final class AnalyticsViewModel: ObservableObject {
    @Published var totalSpend: Decimal = 0
    @Published var spendByCategory: [(String, Decimal)] = []
    @Published var monthlyTrend: [(Date, Decimal)] = []
    @Published var isLoading = false
    
    private let subscriptionUseCase: SubscriptionUseCase

    init(subscriptionUseCase: SubscriptionUseCase) {
        self.subscriptionUseCase = subscriptionUseCase
    }

    func loadAnalytics() async {
        isLoading = true
        do {
            let subscriptions = try await subscriptionUseCase.getAllSubscriptions()
            calculateMetrics(subscriptions: subscriptions)
        } catch {
            print("Analytics load error: \(error)")
        }
        isLoading = false
    }

    private func calculateMetrics(subscriptions: [SmartSubscriptionKit.Subscription]) {
        let active = subscriptions.filter { $0.status == .active }
        
        // Total Monthly Spend (Approx)
        totalSpend = active.reduce(0) { $0 + $1.normalizedMonthlyAmount }
        
        // Spend by Category (Provider for now)
        let grouped = Dictionary(grouping: active, by: { $0.providerName ?? "Other" })
        spendByCategory = grouped.map { (key, subs) in
            (key, subs.reduce(0) { $0 + $1.normalizedMonthlyAmount })
        }.sorted { $0.1 > $1.1 }
        
        // Monthly Trend (Projected next 6 months)
        // This is a simple projection based on current active subscriptions
        // A real trend would look at historical invoices
        var trend: [(Date, Decimal)] = []
        let calendar = Calendar.current
        let today = Date()
        
        for i in 0..<6 {
            if let date = calendar.date(byAdding: .month, value: i, to: today) {
                trend.append((date, totalSpend)) // Constant projection for MVP
            }
        }
        monthlyTrend = trend
    }
}

private extension SmartSubscriptionKit.Subscription {
    var normalizedMonthlyAmount: Decimal {
        let amount = self.amount.amount
        switch self.cadence {
        case .monthly: return amount
        case .yearly: return amount / 12
        case .weekly: return amount * 4.33
        case .customDays(let days): return amount * (30.0 / Decimal(days))
        }
    }
}
