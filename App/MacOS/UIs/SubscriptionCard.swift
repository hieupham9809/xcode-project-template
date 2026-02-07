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
            ZStack {
                Circle()
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    .frame(width: 48, height: 48)

                // Fallback Text Icon (Design has logos, we use text for MVP)
                Text(subscription.name.prefix(1).uppercased())
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.brandDeepBlue)
            }

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
            }

            Spacer()

            // Trailing Info
            #if os(macOS)
                // macOS: Date + Price + Arrow
                HStack(spacing: 16) {
                    if let nextDate = subscription.nextBillingDate {
                        VStack(alignment: .trailing) {
                            Text(nextDate.formatted(date: .abbreviated, time: .omitted))
                                .font(.subheadline)
                                .foregroundStyle(Color.primaryText)
                            Text(subscription.amount.formatted)
                                .font(.subheadline)
                                .foregroundStyle(Color.secondaryText)
                        }
                    } else {
                        Text(subscription.amount.formatted)
                            .font(.headline)
                            .foregroundStyle(Color.primaryText)
                    }

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.secondaryText)
                }
            #else
                // iOS: Price
                Text(subscription.amount.formatted)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.primaryText)
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

        SubscriptionCard(subscription: SmartSubscriptionKit.Subscription(
            name: "Netflix",
            providerName: "Netflix Inc.",
            amount: Money(amount: 15.99, currencyCode: "USD"),
            cadence: .monthly,
            startDate: Date()
        ))
        .padding()
        .frame(width: 400)
    }
}
