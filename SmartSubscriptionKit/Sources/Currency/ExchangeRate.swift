import Foundation

/// Represents exchange rates with a base currency (USD)
public struct ExchangeRates: Codable, Sendable, Equatable {
    public let baseCurrency: String
    public let rates: [String: Decimal]
    public let lastUpdated: Date

    public init(baseCurrency: String, rates: [String: Decimal], lastUpdated: Date) {
        self.baseCurrency = baseCurrency
        self.rates = rates
        self.lastUpdated = lastUpdated
    }

    /// Returns the conversion rate from source currency to target currency.
    /// Uses USD as the base currency for cross-rate calculations.
    /// - Parameters:
    ///   - source: Source currency code (e.g., "EUR")
    ///   - target: Target currency code (e.g., "GBP")
    /// - Returns: The conversion rate, or nil if either currency is not supported
    public func rate(from source: String, to target: String) -> Decimal? {
        let sourceUpper = source.uppercased()
        let targetUpper = target.uppercased()

        // Same currency, no conversion needed
        guard sourceUpper != targetUpper else { return 1 }

        // Get rates for both currencies (relative to base currency USD)
        guard let sourceRate = rates[sourceUpper],
              let targetRate = rates[targetUpper],
              sourceRate != 0
        else { return nil }

        // Cross-rate calculation: target/source
        // If USD is base: EUR->GBP = (GBP/USD) / (EUR/USD) = GBP_rate / EUR_rate
        return targetRate / sourceRate
    }

    /// Check if the rates are older than the specified interval
    /// - Parameter interval: Time interval in seconds (default: 24 hours)
    /// - Returns: True if rates are stale
    public func isStale(olderThan interval: TimeInterval = 86400) -> Bool {
        Date().timeIntervalSince(lastUpdated) > interval
    }
}

/// Supported currency information for UI display
public struct CurrencyInfo: Identifiable, Hashable, Sendable {
    public let code: String
    public let name: String
    public let symbol: String

    public var id: String { code }

    public init(code: String, name: String, symbol: String) {
        self.code = code
        self.name = name
        self.symbol = symbol
    }

    /// Common currencies with their display information
    public static let commonCurrencies: [CurrencyInfo] = [
        CurrencyInfo(code: "USD", name: "US Dollar", symbol: "$"),
        CurrencyInfo(code: "EUR", name: "Euro", symbol: "\u{20AC}"),
        CurrencyInfo(code: "GBP", name: "British Pound", symbol: "\u{00A3}"),
        CurrencyInfo(code: "JPY", name: "Japanese Yen", symbol: "\u{00A5}"),
        CurrencyInfo(code: "CAD", name: "Canadian Dollar", symbol: "CA$"),
        CurrencyInfo(code: "AUD", name: "Australian Dollar", symbol: "A$"),
        CurrencyInfo(code: "CHF", name: "Swiss Franc", symbol: "CHF"),
        CurrencyInfo(code: "CNY", name: "Chinese Yuan", symbol: "\u{00A5}"),
        CurrencyInfo(code: "INR", name: "Indian Rupee", symbol: "\u{20B9}"),
        CurrencyInfo(code: "MXN", name: "Mexican Peso", symbol: "MX$"),
        CurrencyInfo(code: "BRL", name: "Brazilian Real", symbol: "R$"),
        CurrencyInfo(code: "KRW", name: "South Korean Won", symbol: "\u{20A9}"),
        CurrencyInfo(code: "SGD", name: "Singapore Dollar", symbol: "S$"),
        CurrencyInfo(code: "HKD", name: "Hong Kong Dollar", symbol: "HK$"),
        CurrencyInfo(code: "NOK", name: "Norwegian Krone", symbol: "kr"),
        CurrencyInfo(code: "SEK", name: "Swedish Krona", symbol: "kr"),
        CurrencyInfo(code: "DKK", name: "Danish Krone", symbol: "kr"),
        CurrencyInfo(code: "NZD", name: "New Zealand Dollar", symbol: "NZ$"),
        CurrencyInfo(code: "ZAR", name: "South African Rand", symbol: "R"),
        CurrencyInfo(code: "RUB", name: "Russian Ruble", symbol: "\u{20BD}"),
        CurrencyInfo(code: "TRY", name: "Turkish Lira", symbol: "\u{20BA}"),
        CurrencyInfo(code: "PLN", name: "Polish Zloty", symbol: "z\u{0142}"),
        CurrencyInfo(code: "THB", name: "Thai Baht", symbol: "\u{0E3F}"),
        CurrencyInfo(code: "IDR", name: "Indonesian Rupiah", symbol: "Rp"),
        CurrencyInfo(code: "VND", name: "Vietnamese Dong", symbol: "\u{20AB}"),
    ]
}
