import XCTest
@testable import SmartSubscriptionKit

/// Mock rate provider for testing
actor MockRateProvider: ExchangeRateProviding {
    private let mockRates: [String: Decimal]
    private var saveCallCount = 0

    init(rates: [String: Decimal] = ["USD": 1.0, "EUR": 0.92, "GBP": 0.79, "JPY": 149.50]) {
        self.mockRates = rates
    }

    func loadRates() async throws -> ExchangeRates {
        ExchangeRates(baseCurrency: "USD", rates: mockRates, lastUpdated: Date())
    }

    func fetchLatestRates() async throws -> ExchangeRates {
        ExchangeRates(baseCurrency: "USD", rates: mockRates, lastUpdated: Date())
    }

    func saveRates(_ rates: ExchangeRates) async throws {
        saveCallCount += 1
    }

    func getSaveCallCount() -> Int {
        saveCallCount
    }
}

/// Mock rate provider that fails
actor FailingRateProvider: ExchangeRateProviding {
    func loadRates() async throws -> ExchangeRates {
        throw ExchangeRateError.noLocalRates
    }

    func fetchLatestRates() async throws -> ExchangeRates {
        throw ExchangeRateError.networkError("Mock network failure")
    }

    func saveRates(_ rates: ExchangeRates) async throws {}
}

final class CurrencyConverterTests: XCTestCase {

    func testSameCurrencyReturnsOriginal() async throws {
        let converter = CurrencyConverter(rateProvider: MockRateProvider())
        let result = try await converter.convert(100, from: "USD", to: "USD")
        XCTAssertEqual(result, 100)
    }

    func testSameCurrencyCaseInsensitive() async throws {
        let converter = CurrencyConverter(rateProvider: MockRateProvider())
        let result = try await converter.convert(100, from: "usd", to: "USD")
        XCTAssertEqual(result, 100)
    }

    func testConversionWithKnownRates() async throws {
        let mockProvider = MockRateProvider(rates: ["USD": 1.0, "EUR": 0.92])
        let converter = CurrencyConverter(rateProvider: mockProvider)
        let result = try await converter.convert(100, from: "USD", to: "EUR")
        XCTAssertEqual(result, 92) // 100 * 0.92
    }

    func testReverseConversion() async throws {
        // EUR to USD: 100 EUR / 0.92 = ~108.70
        let mockProvider = MockRateProvider(rates: ["USD": 1.0, "EUR": 0.92])
        let converter = CurrencyConverter(rateProvider: mockProvider)
        let result = try await converter.convert(100, from: "EUR", to: "USD")

        // Expected: 100 / 0.92 = 108.695652...
        let expected = Decimal(100) / Decimal(0.92)
        XCTAssertEqual(result, expected)
    }

    func testCrossConversion() async throws {
        // EUR to GBP: (GBP/USD) / (EUR/USD) = 0.79 / 0.92 = 0.858695...
        let mockProvider = MockRateProvider(rates: ["USD": 1.0, "EUR": 0.92, "GBP": 0.79])
        let converter = CurrencyConverter(rateProvider: mockProvider)
        let result = try await converter.convert(100, from: "EUR", to: "GBP")

        // Expected: 100 * (0.79 / 0.92)
        let expected = Decimal(100) * (Decimal(0.79) / Decimal(0.92))
        XCTAssertEqual(result, expected)
    }

    func testUnknownCurrencyReturnsFallback() async throws {
        let converter = CurrencyConverter(rateProvider: MockRateProvider())
        // "XYZ" is not in the mock rates
        let result = try await converter.convert(100, from: "XYZ", to: "USD")
        // Should return original amount as fallback
        XCTAssertEqual(result, 100)
    }

    func testConvertMoneyObject() async throws {
        let mockProvider = MockRateProvider(rates: ["USD": 1.0, "EUR": 0.92])
        let converter = CurrencyConverter(rateProvider: mockProvider)

        let money = Money(amount: 100, currencyCode: "USD")
        let converted = try await converter.convert(money, to: "EUR")

        XCTAssertEqual(converted.amount, 92)
        XCTAssertEqual(converted.currencyCode, "EUR")
    }

    func testFailedRateLoadReturnsFallback() async throws {
        let converter = CurrencyConverter(rateProvider: FailingRateProvider())
        // Should return original amount when rates fail to load
        let result = try await converter.convert(100, from: "USD", to: "EUR")
        XCTAssertEqual(result, 100)
    }

    func testIsRatesStale() async {
        let converter = CurrencyConverter(rateProvider: MockRateProvider())

        // Before loading, rates should be stale
        let isStaleBeforeLoad = await converter.isRatesStale
        XCTAssertTrue(isStaleBeforeLoad)

        // Load rates
        _ = try? await converter.convert(100, from: "USD", to: "EUR")

        // After loading, rates should not be stale
        let isStaleAfterLoad = await converter.isRatesStale
        XCTAssertFalse(isStaleAfterLoad)
    }

    func testRefreshRates() async throws {
        let converter = CurrencyConverter(rateProvider: MockRateProvider())

        // Refresh rates
        try await converter.refreshRates()

        // Rates should be loaded
        let rates = await converter.exchangeRates
        XCTAssertNotNil(rates)
        XCTAssertEqual(rates?.baseCurrency, "USD")
    }
}
