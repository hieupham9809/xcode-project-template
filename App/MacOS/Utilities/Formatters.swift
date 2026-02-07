import Foundation
import SmartSubscriptionKit

enum Formatters {
    /// Zero-decimal currencies that should not display fractional amounts
    static let zeroDecimalCurrencies: Set<String> = ["VND", "JPY", "KRW", "IDR", "HUF", "CLP", "ISK", "UGX", "RWF"]

    /// Creates a currency formatter with Excel standard separators
    /// - Period (.) as decimal separator
    /// - Comma (,) as thousands/grouping separator
    ///
    /// NOTE: We must set `locale = Locale(identifier: "en_US")` to enforce Excel standard format.
    /// Without this, NumberFormatter uses currency-specific locale rules that override our separators.
    /// For example, VND in Vietnamese locale uses period for thousands (268.129), not comma.
    static func currencyFormatter(for currencyCode: String) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency

        // CRITICAL: Force en_US locale to ensure Excel standard format
        // This prevents currency-specific locale rules from overriding our separators
        formatter.locale = Locale(identifier: "en_US")

        // Set currency code AFTER locale to get correct symbol
        formatter.currencyCode = currencyCode

        // Excel standard: comma for thousands, period for decimals
        formatter.groupingSeparator = ","
        formatter.decimalSeparator = "."
        formatter.usesGroupingSeparator = true

        // Zero-decimal currencies use whole numbers only
        if zeroDecimalCurrencies.contains(currencyCode.uppercased()) {
            formatter.maximumFractionDigits = 0
            formatter.minimumFractionDigits = 0
        } else {
            formatter.maximumFractionDigits = 2
            formatter.minimumFractionDigits = 0 // Allow $20 instead of $20.00 if exact
        }

        return formatter
    }

    static let date: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}

extension Money {
    var formatted: String {
        let formatter = Formatters.currencyFormatter(for: currencyCode)
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(currencyCode) \(amount)"
    }
}

extension Decimal {
    /// Formats the decimal as currency with Excel standard separators
    /// - Parameter currencyCode: ISO 4217 currency code (e.g., "USD", "VND")
    /// - Returns: Formatted currency string with comma for thousands, period for decimals
    func formattedAsCurrency(code currencyCode: String) -> String {
        let formatter = Formatters.currencyFormatter(for: currencyCode)
        return formatter.string(from: self as NSDecimalNumber) ?? "\(currencyCode) \(self)"
    }
}
