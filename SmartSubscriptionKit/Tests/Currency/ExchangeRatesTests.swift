import XCTest
@testable import SmartSubscriptionKit

final class ExchangeRatesTests: XCTestCase {

    func testRateSameCurrency() {
        let rates = ExchangeRates(
            baseCurrency: "USD",
            rates: ["USD": 1.0, "EUR": 0.92],
            lastUpdated: Date()
        )

        let rate = rates.rate(from: "USD", to: "USD")
        XCTAssertEqual(rate, 1)
    }

    func testRateCaseInsensitive() {
        let rates = ExchangeRates(
            baseCurrency: "USD",
            rates: ["USD": 1.0, "EUR": 0.92],
            lastUpdated: Date()
        )

        let rate = rates.rate(from: "usd", to: "eur")
        XCTAssertEqual(rate, Decimal(0.92))
    }

    func testRateFromBaseToTarget() {
        let rates = ExchangeRates(
            baseCurrency: "USD",
            rates: ["USD": 1.0, "EUR": 0.92, "GBP": 0.79],
            lastUpdated: Date()
        )

        // USD to EUR
        let usdToEur = rates.rate(from: "USD", to: "EUR")
        XCTAssertEqual(usdToEur, Decimal(0.92))

        // USD to GBP
        let usdToGbp = rates.rate(from: "USD", to: "GBP")
        XCTAssertEqual(usdToGbp, Decimal(0.79))
    }

    func testRateFromTargetToBase() {
        let rates = ExchangeRates(
            baseCurrency: "USD",
            rates: ["USD": 1.0, "EUR": 0.92],
            lastUpdated: Date()
        )

        // EUR to USD: 1 / 0.92
        let eurToUsd = rates.rate(from: "EUR", to: "USD")
        XCTAssertEqual(eurToUsd, Decimal(1.0) / Decimal(0.92))
    }

    func testCrossRate() {
        let rates = ExchangeRates(
            baseCurrency: "USD",
            rates: ["USD": 1.0, "EUR": 0.92, "GBP": 0.79],
            lastUpdated: Date()
        )

        // EUR to GBP: 0.79 / 0.92
        let eurToGbp = rates.rate(from: "EUR", to: "GBP")
        XCTAssertEqual(eurToGbp, Decimal(0.79) / Decimal(0.92))
    }

    func testRateUnknownCurrency() {
        let rates = ExchangeRates(
            baseCurrency: "USD",
            rates: ["USD": 1.0, "EUR": 0.92],
            lastUpdated: Date()
        )

        let rate = rates.rate(from: "XYZ", to: "USD")
        XCTAssertNil(rate)
    }

    func testIsStale() {
        // Fresh rates (now)
        let freshRates = ExchangeRates(
            baseCurrency: "USD",
            rates: ["USD": 1.0],
            lastUpdated: Date()
        )
        XCTAssertFalse(freshRates.isStale())

        // Old rates (25 hours ago)
        let oldDate = Date().addingTimeInterval(-25 * 60 * 60)
        let oldRates = ExchangeRates(
            baseCurrency: "USD",
            rates: ["USD": 1.0],
            lastUpdated: oldDate
        )
        XCTAssertTrue(oldRates.isStale())

        // Rates with custom threshold (1 hour)
        let recentDate = Date().addingTimeInterval(-30 * 60) // 30 minutes ago
        let recentRates = ExchangeRates(
            baseCurrency: "USD",
            rates: ["USD": 1.0],
            lastUpdated: recentDate
        )
        XCTAssertFalse(recentRates.isStale(olderThan: 3600)) // 1 hour threshold
    }

    func testCodable() throws {
        let rates = ExchangeRates(
            baseCurrency: "USD",
            rates: ["USD": 1.0, "EUR": 0.92, "GBP": 0.79],
            lastUpdated: Date(timeIntervalSince1970: 1700000000)
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(rates)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(ExchangeRates.self, from: data)

        XCTAssertEqual(decoded.baseCurrency, rates.baseCurrency)
        XCTAssertEqual(decoded.rates, rates.rates)
        XCTAssertEqual(decoded.lastUpdated, rates.lastUpdated)
    }
}
