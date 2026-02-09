import SmartSubscriptionKit
import SwiftUI

struct SubscriptionCard: View {
    let subscription: SmartSubscriptionKit.Subscription

    // Fintech colors based on analysis
    #if os(macOS)
        private let cardBackground = Color(nsColor: .windowBackgroundColor) // Adaptive system color
    #else
        private let cardBackground = Color(uiColor: .secondarySystemBackground)
    #endif
    private let accentColor = Color.accentColor // Use app accent

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // Icon
            ServiceIconView(subscription: subscription)

            // Name & Provider
            VStack(alignment: .leading, spacing: 4) {
                Text(subscription.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.primaryText)
                    .lineLimit(1)

                if let providerName = subscription.providerName, !providerName.isEmpty {
                    Text(providerName)
                        .font(.subheadline)
                        .foregroundStyle(Color.secondaryText)
                        .lineLimit(1)
                } else if let notes = subscription.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.subheadline)
                        .foregroundStyle(Color.secondaryText)
                        .lineLimit(1)
                }
                
                // Billing Period Badge
                Text(subscription.cadence.description)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(Capsule())
                    .foregroundColor(.secondary)
            }

            // Billing Urgency Badge - Moved to trailing

            Spacer()

            // Trailing Info
            #if os(macOS)
                // macOS: Date + Price + Arrow
                HStack(spacing: 16) {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(subscription.amount.formatted)
                            .font(.headline)
                            .foregroundStyle(Color.primaryText)
                        
                        if let days = subscription.daysUntilBilling {
                            BillingBadge(days: days, urgency: subscription.billingUrgency)
                        }
                    }

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.secondaryText)
                }
            #else
                // iOS: Price + Badge
                VStack(alignment: .trailing, spacing: 4) {
                    Text(subscription.amount.formatted)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.primaryText)
                    
                    if let days = subscription.daysUntilBilling {
                        BillingBadge(days: days, urgency: subscription.billingUrgency)
                    }
                }
            #endif
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        // Accessibility
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(subscription.name)\(subscription.providerName.map { ", by \($0)" } ?? ""), \(subscription.amount.formatted)")
        .accessibilityHint("Double tap to view details")
    }
}

// MARK: - Billing Badge

struct BillingBadge: View {
    let days: Int
    let urgency: SmartSubscriptionKit.Subscription.BillingUrgency

    private var badgeColor: Color {
        switch urgency {
        case .urgent: .urgentRed
        case .warning: .warningOrange
        case .safe: .safeGreen
        case .unknown: .secondaryText
        }
    }

    private var badgeText: String {
        if days == 0 { return "Today" }
        if days == 1 { return "Tomorrow" }
        if days < 0 { return "Overdue" }
        return "\(days)d"
    }

    var body: some View {
        Text(badgeText)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(badgeColor)
            .clipShape(Capsule())
    }
}

// Removing local Money extension as it is now in Formatters.swift

extension SmartSubscriptionKit.Subscription.BillingCadence {
    var description: String {
        switch self {
        case .weekly: "Weekly"
        case .monthly: "Monthly"
        case .yearly: "Yearly"
        case let .customDays(days): "Every \(days) days"
        }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.1)
            .ignoresSafeArea()

        VStack(spacing: 16) {
            // Urgent (2 days)
            SubscriptionCard(subscription: SmartSubscriptionKit.Subscription(
                name: "Netflix",
                providerName: "Netflix Inc.",
                amount: Money(amount: 15.99, currencyCode: "USD"),
                cadence: .monthly,
                startDate: Date(),
                nextBillingDate: Calendar.current.date(byAdding: .day, value: 2, to: Date())
            ))

            // Warning (5 days)
            SubscriptionCard(subscription: SmartSubscriptionKit.Subscription(
                name: "Spotify",
                providerName: "Spotify AB",
                amount: Money(amount: 9.99, currencyCode: "USD"),
                cadence: .monthly,
                startDate: Date(),
                nextBillingDate: Calendar.current.date(byAdding: .day, value: 5, to: Date())
            ))

            // Safe (15 days)
            SubscriptionCard(subscription: SmartSubscriptionKit.Subscription(
                name: "iCloud",
                providerName: "Apple",
                amount: Money(amount: 2.99, currencyCode: "USD"),
                cadence: .monthly,
                startDate: Date(),
                nextBillingDate: Calendar.current.date(byAdding: .day, value: 15, to: Date())
            ))
        }
        .padding()
        .frame(width: 400)
    }
}
