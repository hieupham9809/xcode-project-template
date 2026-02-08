import Foundation

// MARK: - Period Conversion Constants

/// Constants for precise period conversions based on the Gregorian calendar.
/// These values ensure consistent and accurate amount normalization across the app.
public enum PeriodConversionConstants {
    /// Number of weeks in a year (fixed by definition)
    public static let weeksPerYear: Decimal = 52

    /// Number of months in a year (fixed)
    public static let monthsPerYear: Decimal = 12

    /// Number of weeks per month, derived from weeksPerYear / monthsPerYear
    /// Value: 4.333... (more precise than commonly used 4.33)
    public static let weeksPerMonth: Decimal = weeksPerYear / monthsPerYear

    /// Average days per year accounting for leap years (365.25)
    public static let daysPerYear: Decimal = Decimal(string: "365.25")!

    /// Average days per month, derived from daysPerYear / monthsPerYear
    /// Value: 30.4375 (more precise than commonly used 30)
    public static let daysPerMonth: Decimal = daysPerYear / monthsPerYear

    /// Days per week (fixed)
    public static let daysPerWeek: Decimal = 7
}

// MARK: - Normalization Period

/// Target period for amount normalization.
/// Used to convert subscription amounts to a common display period.
public enum NormalizationPeriod: String, CaseIterable, Identifiable, Sendable {
    case weekly = "Weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"

    public var id: String { rawValue }

    /// Short suffix for display (e.g., "/wk", "/mo", "/yr")
    public var displaySuffix: String {
        switch self {
        case .weekly: return "/wk"
        case .monthly: return "/mo"
        case .yearly: return "/yr"
        }
    }
}

// MARK: - Amount Normalizer

/// A service for normalizing subscription amounts across different billing cadences.
///
/// This centralizes all period conversion logic with precise mathematical constants,
/// eliminating duplicate code and ensuring consistent calculations throughout the app.
///
/// ## Example Usage
/// ```swift
/// let monthlyAmount = AmountNormalizer.normalize(
///     12.00,  // Weekly subscription cost
///     from: .weekly,
///     to: .monthly
/// )
/// // Result: 52.00 (12.00 × 52/12)
/// ```
public enum AmountNormalizer {

    /// Normalizes a subscription amount from its billing cadence to a target display period.
    ///
    /// - Parameters:
    ///   - amount: The original subscription amount
    ///   - cadence: The billing cadence of the subscription
    ///   - period: The target display period
    /// - Returns: The normalized amount with high precision
    ///
    /// ## Conversion Formulas
    /// | From \ To     | Monthly                  | Yearly           |
    /// |---------------|--------------------------|------------------|
    /// | Weekly        | × (52/12) ≈ 4.333        | × 52             |
    /// | Monthly       | × 1                      | × 12             |
    /// | Yearly        | ÷ 12                     | × 1              |
    /// | Custom(N)     | × (30.4375/N)            | × (365.25/N)     |
    public static func normalize(
        _ amount: Decimal,
        from cadence: Subscription.BillingCadence,
        to period: NormalizationPeriod
    ) -> Decimal {
        guard amount != 0 else { return 0 }

        switch (cadence, period) {
        // Weekly conversions
        case (.weekly, .weekly):
            return amount
        case (.weekly, .monthly):
            return amount * PeriodConversionConstants.weeksPerMonth
        case (.weekly, .yearly):
            return amount * PeriodConversionConstants.weeksPerYear

        // Monthly conversions
        case (.monthly, .weekly):
            return amount / PeriodConversionConstants.weeksPerMonth
        case (.monthly, .monthly):
            return amount
        case (.monthly, .yearly):
            return amount * PeriodConversionConstants.monthsPerYear

        // Yearly conversions
        case (.yearly, .weekly):
            return amount / PeriodConversionConstants.weeksPerYear
        case (.yearly, .monthly):
            return amount / PeriodConversionConstants.monthsPerYear
        case (.yearly, .yearly):
            return amount

        // Custom days conversions
        case let (.customDays(days), .weekly):
            return amount * (PeriodConversionConstants.daysPerWeek / Decimal(days))
        case let (.customDays(days), .monthly):
            return amount * (PeriodConversionConstants.daysPerMonth / Decimal(days))
        case let (.customDays(days), .yearly):
            return amount * (PeriodConversionConstants.daysPerYear / Decimal(days))
        }
    }

    /// Normalizes an amount to monthly, convenience method for common use case.
    ///
    /// - Parameters:
    ///   - amount: The original subscription amount
    ///   - cadence: The billing cadence of the subscription
    /// - Returns: The monthly-normalized amount
    public static func normalizeToMonthly(
        _ amount: Decimal,
        from cadence: Subscription.BillingCadence
    ) -> Decimal {
        normalize(amount, from: cadence, to: .monthly)
    }

    /// Normalizes an amount to yearly, convenience method for common use case.
    ///
    /// - Parameters:
    ///   - amount: The original subscription amount
    ///   - cadence: The billing cadence of the subscription
    /// - Returns: The yearly-normalized amount
    public static func normalizeToYearly(
        _ amount: Decimal,
        from cadence: Subscription.BillingCadence
    ) -> Decimal {
        normalize(amount, from: cadence, to: .yearly)
    }
}

// MARK: - Subscription Extension

public extension Subscription {
    /// Returns the amount normalized to the specified period.
    ///
    /// - Parameter period: The target display period
    /// - Returns: The normalized amount
    func normalizedAmount(for period: NormalizationPeriod) -> Decimal {
        AmountNormalizer.normalize(amount.amount, from: cadence, to: period)
    }
}
