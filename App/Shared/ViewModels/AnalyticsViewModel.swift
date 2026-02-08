import Combine
import Foundation
import SmartSubscriptionKit

@MainActor
final class AnalyticsViewModel: ObservableObject {
    @Published var totalSpend: Decimal = 0
    @Published var spendByCategory: [(String, Decimal)] = []
    @Published var monthlyTrend: [(Date, Decimal)] = []
    @Published var isLoading = false
    @Published var displayCurrency: String = "USD"

    private let subscriptionUseCase: SubscriptionUseCase
    private let currencyConverter: CurrencyConverter
    private let settingsStore: SettingsStore
    private var cancellables = Set<AnyCancellable>()
    private var cachedSubscriptions: [SmartSubscriptionKit.Subscription] = []

    init(
        subscriptionUseCase: SubscriptionUseCase,
        currencyConverter: CurrencyConverter = CurrencyConverter(),
        settingsStore: SettingsStore = .shared
    ) {
        self.subscriptionUseCase = subscriptionUseCase
        self.currencyConverter = currencyConverter
        self.settingsStore = settingsStore
        displayCurrency = settingsStore.defaultCurrency

        setupObservers()
    }

    private func setupObservers() {
        NotificationCenter.default.publisher(for: .defaultCurrencyChanged)
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                guard let self,
                      let currency = notification.userInfo?["currency"] as? String
                else { return }
                displayCurrency = currency
                Task {
                    await self.recalculateWithCachedData()
                }
            }
            .store(in: &cancellables)
    }

    func loadAnalytics() async {
        isLoading = true
        do {
            let subscriptions = try await subscriptionUseCase.getAllSubscriptions()
            cachedSubscriptions = subscriptions
            await calculateMetrics(subscriptions: subscriptions)
        } catch {
            print("Analytics load error: \(error)")
        }
        isLoading = false
    }

    private func recalculateWithCachedData() async {
        await calculateMetrics(subscriptions: cachedSubscriptions)
    }

    private func calculateMetrics(subscriptions: [SmartSubscriptionKit.Subscription]) async {
        let active = subscriptions.filter { $0.status == .active }

        // Total Monthly Spend with currency conversion
        var total: Decimal = 0
        for sub in active {
            let monthlyAmount = sub.normalizedMonthlyAmount
            do {
                let converted = try await currencyConverter.convert(
                    monthlyAmount,
                    from: sub.amount.currencyCode,
                    to: displayCurrency
                )
                total += converted
            } catch {
                total += monthlyAmount
            }
        }
        totalSpend = total

        // Spend by Category with currency conversion
        let grouped = Dictionary(grouping: active, by: { $0.providerName ?? "Other" })
        var categorySpend: [(String, Decimal)] = []

        for (key, subs) in grouped {
            var categoryTotal: Decimal = 0
            for sub in subs {
                let monthlyAmount = sub.normalizedMonthlyAmount
                do {
                    let converted = try await currencyConverter.convert(
                        monthlyAmount,
                        from: sub.amount.currencyCode,
                        to: displayCurrency
                    )
                    categoryTotal += converted
                } catch {
                    categoryTotal += monthlyAmount
                }
            }
            categorySpend.append((key, categoryTotal))
        }
        spendByCategory = categorySpend.sorted { $0.1 > $1.1 }

        // Monthly Trend (Projected next 6 months)
        var trend: [(Date, Decimal)] = []
        let calendar = Calendar.current
        let today = Date()

        for i in 0 ..< 6 {
            if let date = calendar.date(byAdding: .month, value: i, to: today) {
                trend.append((date, totalSpend)) // Constant projection for MVP
            }
        }
        monthlyTrend = trend
    }
}

private extension SmartSubscriptionKit.Subscription {
    var normalizedMonthlyAmount: Decimal {
        let amount = amount.amount
        switch cadence {
        case .monthly: return amount
        case .yearly: return amount / 12
        case .weekly: return amount * 4.33
        case let .customDays(days): return amount * (30.0 / Decimal(days))
        }
    }
}
