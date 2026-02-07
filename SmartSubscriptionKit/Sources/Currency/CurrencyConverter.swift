import Foundation
import os

/// Errors that can occur during currency conversion
public enum CurrencyConversionError: Error, Sendable, LocalizedError {
    case unsupportedCurrency(String)
    case noExchangeRates
    case conversionFailed

    public var errorDescription: String? {
        switch self {
        case let .unsupportedCurrency(code):
            return "Unsupported currency: \(code)"
        case .noExchangeRates:
            return "Exchange rates not available"
        case .conversionFailed:
            return "Currency conversion failed"
        }
    }
}

/// Protocol for currency conversion services
public protocol CurrencyConverting: Sendable {
    /// Convert an amount from one currency to another
    /// - Parameters:
    ///   - amount: The amount to convert
    ///   - source: Source currency code
    ///   - target: Target currency code
    /// - Returns: The converted amount
    func convert(_ amount: Decimal, from source: String, to target: String) async throws -> Decimal

    /// Convert Money to target currency
    /// - Parameters:
    ///   - money: The Money instance to convert
    ///   - targetCurrency: Target currency code
    /// - Returns: A new Money instance with converted amount
    func convert(_ money: Money, to targetCurrency: String) async throws -> Money

    /// Get the current exchange rates
    var exchangeRates: ExchangeRates? { get async }

    /// Check if rates are stale (older than 24 hours)
    var isRatesStale: Bool { get async }

    /// Force refresh exchange rates from network
    func refreshRates() async throws
}

/// Actor-based currency converter with cached exchange rates
public actor CurrencyConverter: CurrencyConverting {
    private let rateProvider: ExchangeRateProviding
    private var cachedRates: ExchangeRates?
    private let logger = Logger(subsystem: "SmartSubscription", category: "CurrencyConverter")

    public init(rateProvider: ExchangeRateProviding) {
        self.rateProvider = rateProvider
    }

    /// Convenience initializer with default rate provider
    public init() {
        self.rateProvider = ExchangeRateProvider()
    }

    public var exchangeRates: ExchangeRates? {
        cachedRates
    }

    public var isRatesStale: Bool {
        guard let rates = cachedRates else { return true }
        return rates.isStale()
    }

    public func convert(_ amount: Decimal, from source: String, to target: String) async throws -> Decimal {
        let sourceUpper = source.uppercased()
        let targetUpper = target.uppercased()

        // Same currency, no conversion needed
        guard sourceUpper != targetUpper else { return amount }

        // Load rates if not cached
        if cachedRates == nil {
            do {
                cachedRates = try await rateProvider.loadRates()
            } catch {
                // Log error but don't throw - return original amount as fallback
                logger.warning("Failed to load exchange rates: \(error.localizedDescription). Returning unconverted amount.")
                return amount
            }
        }

        guard let rates = cachedRates else {
            logger.warning("No exchange rates available. Returning unconverted amount.")
            return amount
        }

        guard let rate = rates.rate(from: sourceUpper, to: targetUpper) else {
            // Unknown currency - return original amount with warning
            logger.warning("Unknown currency \(sourceUpper) or \(targetUpper). Returning unconverted amount.")
            return amount
        }

        return amount * rate
    }

    public func convert(_ money: Money, to targetCurrency: String) async throws -> Money {
        let convertedAmount = try await convert(money.amount, from: money.currencyCode, to: targetCurrency)
        return Money(amount: convertedAmount, currencyCode: targetCurrency)
    }

    /// Force refresh rates from network
    public func refreshRates() async throws {
        cachedRates = try await rateProvider.fetchLatestRates()
        logger.info("Exchange rates refreshed. Last updated: \(self.cachedRates?.lastUpdated.description ?? "unknown")")
    }

    /// Preload rates (useful for app startup)
    public func preloadRates() async {
        do {
            cachedRates = try await rateProvider.loadRates()
            logger.info("Exchange rates preloaded successfully")
        } catch {
            logger.warning("Failed to preload exchange rates: \(error.localizedDescription)")
        }
    }
}
