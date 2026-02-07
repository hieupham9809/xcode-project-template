import Foundation
import os

/// Errors that can occur when fetching exchange rates
public enum ExchangeRateError: Error, Sendable, LocalizedError {
    case networkError(String)
    case parseError
    case noLocalRates
    case invalidResponse

    public var errorDescription: String? {
        switch self {
        case let .networkError(message):
            return "Network error: \(message)"
        case .parseError:
            return "Failed to parse exchange rates"
        case .noLocalRates:
            return "No local exchange rates available"
        case .invalidResponse:
            return "Invalid response from exchange rate API"
        }
    }
}

/// Protocol for providing exchange rates
public protocol ExchangeRateProviding: Sendable {
    /// Load rates from local storage or bundled defaults
    func loadRates() async throws -> ExchangeRates

    /// Fetch latest rates from network
    func fetchLatestRates() async throws -> ExchangeRates

    /// Save rates to local storage
    func saveRates(_ rates: ExchangeRates) async throws
}

/// Actor-based exchange rate provider with local caching and network fetching
public actor ExchangeRateProvider: ExchangeRateProviding {
    private let session: URLSession
    private let userDefaults: UserDefaults
    private let logger = Logger(subsystem: "SmartSubscription", category: "ExchangeRateProvider")

    // Free API: exchangerate-api.com (no API key required for basic usage)
    private let apiURL = "https://api.exchangerate-api.com/v4/latest/USD"

    private static let cacheKey = "CachedExchangeRates"

    public init(
        session: URLSession = .shared,
        userDefaults: UserDefaults = .standard
    ) {
        self.session = session
        self.userDefaults = userDefaults
    }

    /// Load rates with fallback chain: local cache -> bundled -> network
    public func loadRates() async throws -> ExchangeRates {
        // 1. Try to load from local cache first
        if let localRates = loadLocalRates() {
            logger.debug("Loaded exchange rates from local cache")
            return localRates
        }

        // 2. Fall back to bundled rates
        if let bundledRates = loadBundledRates() {
            logger.debug("Loaded exchange rates from bundled JSON")
            return bundledRates
        }

        // 3. Last resort: try network
        logger.info("No local or bundled rates found, fetching from network")
        return try await fetchLatestRates()
    }

    /// Fetch latest rates from network API
    public func fetchLatestRates() async throws -> ExchangeRates {
        guard let url = URL(string: apiURL) else {
            throw ExchangeRateError.networkError("Invalid URL")
        }

        logger.info("Fetching exchange rates from \(self.apiURL)")

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ExchangeRateError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw ExchangeRateError.networkError("HTTP \(httpResponse.statusCode)")
        }

        // Parse the API response
        struct APIResponse: Decodable {
            let base: String
            let rates: [String: Double]
        }

        let decoder = JSONDecoder()
        let apiResponse: APIResponse
        do {
            apiResponse = try decoder.decode(APIResponse.self, from: data)
        } catch {
            logger.error("Failed to parse API response: \(error.localizedDescription)")
            throw ExchangeRateError.parseError
        }

        // Convert Double to Decimal for precision
        let decimalRates = apiResponse.rates.reduce(into: [String: Decimal]()) { result, pair in
            result[pair.key] = Decimal(pair.value)
        }

        let rates = ExchangeRates(
            baseCurrency: apiResponse.base,
            rates: decimalRates,
            lastUpdated: Date()
        )

        // Cache the rates locally
        try await saveRates(rates)

        logger.info("Successfully fetched and cached \(decimalRates.count) exchange rates")
        return rates
    }

    /// Save rates to UserDefaults for local caching
    public func saveRates(_ rates: ExchangeRates) async throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(rates)
        userDefaults.set(data, forKey: Self.cacheKey)
        logger.debug("Saved exchange rates to local cache")
    }

    // MARK: - Private Helpers

    private func loadLocalRates() -> ExchangeRates? {
        guard let data = userDefaults.data(forKey: Self.cacheKey) else {
            return nil
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(ExchangeRates.self, from: data)
    }

    private func loadBundledRates() -> ExchangeRates? {
        // Try to find the bundled JSON file in the module bundle
        guard let url = Bundle.module.url(forResource: "exchange_rates", withExtension: "json") else {
            logger.warning("Bundled exchange_rates.json not found")
            return nil
        }

        guard let data = try? Data(contentsOf: url) else {
            logger.warning("Failed to read bundled exchange_rates.json")
            return nil
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(ExchangeRates.self, from: data)
    }
}
