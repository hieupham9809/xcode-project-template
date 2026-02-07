import Combine
import Foundation
import SmartSubscriptionKit

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
    @Published var totalSpendFormatted: String = "$0.00"
    @Published var defaultCurrency: String = "USD"

    private let subscriptionUseCase: SubscriptionUseCase
    private let currencyConverter: CurrencyConverter
    private let settingsStore: SettingsStore
    private var cancellables = Set<AnyCancellable>()

    init(
        subscriptionUseCase: SubscriptionUseCase,
        currencyConverter: CurrencyConverter = CurrencyConverter(),
        settingsStore: SettingsStore = .shared
    ) {
        self.subscriptionUseCase = subscriptionUseCase
        self.currencyConverter = currencyConverter
        self.settingsStore = settingsStore
        defaultCurrency = settingsStore.defaultCurrency

        setupObservers()
    }

    private func setupObservers() {
        // Observe currency changes
        NotificationCenter.default.publisher(for: .defaultCurrencyChanged)
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                guard let self,
                      let currency = notification.userInfo?["currency"] as? String
                else { return }
                defaultCurrency = currency
                Task {
                    await self.calculateTotalSpend()
                }
            }
            .store(in: &cancellables)

        // Observe period changes to recalculate
        $selectedPeriod
            .dropFirst()
            .sink { [weak self] _ in
                guard let self else { return }
                Task {
                    await self.calculateTotalSpend()
                }
            }
            .store(in: &cancellables)
    }

    /// Calculate total spend with currency conversion
    func calculateTotalSpend() async {
        var total: Decimal = 0

        for sub in subscriptions where sub.status == .active {
            let normalizedAmount = sub.normalizedAmount(for: selectedPeriod)

            // Convert to user's default currency
            do {
                let converted = try await currencyConverter.convert(
                    normalizedAmount,
                    from: sub.amount.currencyCode,
                    to: defaultCurrency
                )
                total += converted
            } catch {
                // Fallback: add unconverted amount if conversion fails
                total += normalizedAmount
            }
        }

        let formatter = Formatters.currencyFormatter(for: defaultCurrency)
        totalSpendFormatted = formatter.string(from: total as NSDecimalNumber) ?? "$0.00"
    }

    /// Legacy computed property for backward compatibility
    var totalSpend: String {
        totalSpendFormatted
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
            await calculateTotalSpend()
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
        let amount = amount.amount
        switch (cadence, period) {
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
        case let (.customDays(days), .monthly):
            return amount * (30.0 / Decimal(days))
        case let (.customDays(days), .yearly):
            return amount * (365.0 / Decimal(days))
        }
    }
}
