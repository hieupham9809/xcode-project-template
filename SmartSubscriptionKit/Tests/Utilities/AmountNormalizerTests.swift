import XCTest
@testable import SmartSubscriptionKit

final class AmountNormalizerTests: XCTestCase {

    // MARK: - Constants Tests

    func testPeriodConversionConstants_WeeksPerMonth_IsPrecise() {
        // 52 / 12 = 4.333...
        let expected = Decimal(52) / Decimal(12)
        XCTAssertEqual(PeriodConversionConstants.weeksPerMonth, expected)
    }

    func testPeriodConversionConstants_DaysPerMonth_IsPrecise() {
        // 365.25 / 12 = 30.4375
        let expected = Decimal(string: "30.4375")!
        XCTAssertEqual(PeriodConversionConstants.daysPerMonth, expected)
    }

    // MARK: - Monthly to Monthly (No Conversion)

    func testMonthlyToMonthly_NoConversion() {
        let amount: Decimal = 15.99
        let result = AmountNormalizer.normalize(amount, from: .monthly, to: .monthly)
        XCTAssertEqual(result, amount)
    }

    // MARK: - Monthly to Yearly

    func testMonthlyToYearly_Multiply12() {
        let amount: Decimal = 15.99
        let result = AmountNormalizer.normalize(amount, from: .monthly, to: .yearly)
        XCTAssertEqual(result, amount * 12)
    }

    // MARK: - Yearly to Monthly

    func testYearlyToMonthly_Divide12() {
        let amount: Decimal = 120.00
        let result = AmountNormalizer.normalize(amount, from: .yearly, to: .monthly)
        XCTAssertEqual(result, 10.00)
    }

    // MARK: - Yearly to Yearly (No Conversion)

    func testYearlyToYearly_NoConversion() {
        let amount: Decimal = 99.99
        let result = AmountNormalizer.normalize(amount, from: .yearly, to: .yearly)
        XCTAssertEqual(result, amount)
    }

    // MARK: - Weekly Conversions

    func testWeeklyToMonthly_PreciseConversion() {
        let amount: Decimal = 12.00
        let result = AmountNormalizer.normalize(amount, from: .weekly, to: .monthly)
        // 12 * (52/12) = 52.00
        let expected = amount * PeriodConversionConstants.weeksPerMonth
        XCTAssertEqual(result, expected)
    }

    func testWeeklyToYearly_Multiply52() {
        let amount: Decimal = 10.00
        let result = AmountNormalizer.normalize(amount, from: .weekly, to: .yearly)
        XCTAssertEqual(result, 520.00)
    }

    func testWeeklyToWeekly_NoConversion() {
        let amount: Decimal = 7.50
        let result = AmountNormalizer.normalize(amount, from: .weekly, to: .weekly)
        XCTAssertEqual(result, amount)
    }

    // MARK: - Custom Days Conversions

    func testCustomDaysToMonthly_PreciseConversion() {
        // Every 14 days (bi-weekly)
        let amount: Decimal = 20.00
        let result = AmountNormalizer.normalize(amount, from: .customDays(14), to: .monthly)
        // 20 * (30.4375 / 14) ≈ 43.48
        let expected = amount * (PeriodConversionConstants.daysPerMonth / 14)
        XCTAssertEqual(result, expected)
    }

    func testCustomDaysToYearly_PreciseConversion() {
        // Every 30 days
        let amount: Decimal = 10.00
        let result = AmountNormalizer.normalize(amount, from: .customDays(30), to: .yearly)
        // 10 * (365.25 / 30) = 121.75
        let expected = amount * (PeriodConversionConstants.daysPerYear / 30)
        XCTAssertEqual(result, expected)
    }

    func testCustomDays365ToYearly_ApproximatelyEqual() {
        // Every 365 days should be approximately yearly
        let amount: Decimal = 100.00
        let result = AmountNormalizer.normalize(amount, from: .customDays(365), to: .yearly)
        // 100 * (365.25 / 365) ≈ 100.07
        assertDecimalEqual(result, amount * (PeriodConversionConstants.daysPerYear / 365), accuracy: Decimal(0.01))
    }

    // MARK: - Mixed Cadences Total Calculation

    func testMixedCadences_TotalCalculation() {
        // Netflix: $15.99/month
        // Spotify: $9.99/month
        // Weekly Gym: $12.00/week
        // Annual Insurance: $1,200/year

        let netflix = AmountNormalizer.normalize(Decimal(string: "15.99")!, from: .monthly, to: .monthly)
        let spotify = AmountNormalizer.normalize(Decimal(string: "9.99")!, from: .monthly, to: .monthly)
        let gym = AmountNormalizer.normalize(Decimal(12), from: .weekly, to: .monthly)
        let insurance = AmountNormalizer.normalize(Decimal(1200), from: .yearly, to: .monthly)

        let monthlyTotal = netflix + spotify + gym + insurance
        // 15.99 + 9.99 + 52.00 + 100.00 = 177.98
        let expectedMonthly = Decimal(string: "15.99")! + Decimal(string: "9.99")! +
            (Decimal(12) * PeriodConversionConstants.weeksPerMonth) +
            (Decimal(1200) / PeriodConversionConstants.monthsPerYear)

        XCTAssertEqual(monthlyTotal, expectedMonthly)
    }

    // MARK: - Precision Tests

    func testPrecisionMaintained_LargeAmounts() {
        let amount: Decimal = 999999.99
        let result = AmountNormalizer.normalize(amount, from: .monthly, to: .yearly)
        XCTAssertEqual(result, amount * 12)
    }

    func testPrecisionMaintained_SmallAmounts() {
        let amount: Decimal = Decimal(string: "0.01")!
        let result = AmountNormalizer.normalize(amount, from: .yearly, to: .monthly)
        let expected = amount / 12
        XCTAssertEqual(result, expected)
    }

    // MARK: - Edge Cases

    func testZeroAmount_ReturnsZero() {
        XCTAssertEqual(AmountNormalizer.normalize(0, from: .monthly, to: .yearly), 0)
        XCTAssertEqual(AmountNormalizer.normalize(0, from: .weekly, to: .monthly), 0)
        XCTAssertEqual(AmountNormalizer.normalize(0, from: .yearly, to: .monthly), 0)
        XCTAssertEqual(AmountNormalizer.normalize(0, from: .customDays(30), to: .monthly), 0)
    }

    func testNegativeAmount_HandledCorrectly() {
        // Negative amounts (refunds/credits) should normalize correctly
        let amount: Decimal = -10.00
        let result = AmountNormalizer.normalize(amount, from: .monthly, to: .yearly)
        XCTAssertEqual(result, -120.00)
    }

    // MARK: - Convenience Methods

    func testNormalizeToMonthly_ConvenienceMethod() {
        let amount: Decimal = 120.00
        let result = AmountNormalizer.normalizeToMonthly(amount, from: .yearly)
        XCTAssertEqual(result, 10.00)
    }

    func testNormalizeToYearly_ConvenienceMethod() {
        let amount: Decimal = 10.00
        let result = AmountNormalizer.normalizeToYearly(amount, from: .monthly)
        XCTAssertEqual(result, 120.00)
    }

    // MARK: - NormalizationPeriod Tests

    func testNormalizationPeriod_DisplaySuffix() {
        XCTAssertEqual(NormalizationPeriod.weekly.displaySuffix, "/wk")
        XCTAssertEqual(NormalizationPeriod.monthly.displaySuffix, "/mo")
        XCTAssertEqual(NormalizationPeriod.yearly.displaySuffix, "/yr")
    }

    // MARK: - Reverse Conversions

    func testMonthlyToWeekly_ReverseConversion() {
        let amount: Decimal = 52.00
        let result = AmountNormalizer.normalize(amount, from: .monthly, to: .weekly)
        // 52 / (52/12) = 12
        let expected = amount / PeriodConversionConstants.weeksPerMonth
        XCTAssertEqual(result, expected)
    }

    func testYearlyToWeekly_ReverseConversion() {
        let amount: Decimal = 520.00
        let result = AmountNormalizer.normalize(amount, from: .yearly, to: .weekly)
        XCTAssertEqual(result, 10.00)
    }

    // MARK: - Custom Days to Weekly

    func testCustomDaysToWeekly_Conversion() {
        // Every 14 days (bi-weekly)
        let amount: Decimal = 20.00
        let result = AmountNormalizer.normalize(amount, from: .customDays(14), to: .weekly)
        // 20 * (7 / 14) = 10
        XCTAssertEqual(result, 10.00)
    }
}

// MARK: - Decimal Accuracy Helper

private extension AmountNormalizerTests {
    func assertDecimalEqual(
        _ expression1: Decimal,
        _ expression2: Decimal,
        accuracy: Decimal,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let difference = abs(expression1 - expression2)
        XCTAssertLessThanOrEqual(
            difference,
            accuracy,
            "(\(expression1)) is not equal to (\(expression2)) +/- (\(accuracy))",
            file: file,
            line: line
        )
    }
}
