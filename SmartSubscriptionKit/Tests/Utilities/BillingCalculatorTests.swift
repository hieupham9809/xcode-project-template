import XCTest
@testable import SmartSubscriptionKit

final class BillingCalculatorTests: XCTestCase {
    func testCalculateNextBillingDate_Monthly_Future() {
        // Given
        let startDate = Date() // Now
        let cadence = Subscription.BillingCadence.monthly

        // When
        let nextDate = BillingCalculator.calculateNextBillingDate(startDate: startDate, cadence: cadence)

        // Then
        // Since start date is now (future relative to slightly past or just being "now"), it should return start date if we consider start date as "next" if it hasn't happened yet?
        // Wait, logic says: if startDate > referenceDate { return startDate }
        // if startDate == referenceDate (approx), loop condition until > referenceDate.

        // Let's be precise.
        // Start Date: Jan 1, 2023
        // Reference Date: Jan 15, 2023
        // Cadence: Monthly
        // Expected: Feb 1, 2023

        let calendar = Calendar.current
        let startDateFixed = calendar.date(from: DateComponents(year: 2023, month: 1, day: 1))!
        let referenceDate = calendar.date(from: DateComponents(year: 2023, month: 1, day: 15))!

        let result = BillingCalculator.calculateNextBillingDate(startDate: startDateFixed, cadence: .monthly, referenceDate: referenceDate)

        let expected = calendar.date(from: DateComponents(year: 2023, month: 2, day: 1))!
        XCTAssertEqual(result, expected)
    }

    func testCalculateNextBillingDate_Yearly_Past() {
        // Given
        // Start Date: Jan 1, 2020
        // Reference Date: Jan 1, 2023
        // Cadence: Yearly
        // Expected: Jan 1, 2024 (Since Jan 1 2023 == Reference, loop continues while <= reference?
        // Logic: while nextDate <= referenceDate.
        // Jan 1 2020 -> 2021 -> 2022 -> 2023.
        // If 2023 <= 2023 (Yes), then add 1 year -> 2024.

        let calendar = Calendar.current
        let startDateFixed = calendar.date(from: DateComponents(year: 2020, month: 1, day: 1))!
        let referenceDate = calendar.date(from: DateComponents(year: 2023, month: 1, day: 1))!

        let result = BillingCalculator.calculateNextBillingDate(startDate: startDateFixed, cadence: .yearly, referenceDate: referenceDate)

        let expected = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1))!
        XCTAssertEqual(result, expected)
    }

    func testCalculateNextBillingDate_Weekly() {
        // Start: Jan 1, 2023 (Sunday)
        // Reference: Jan 10, 2023 (Tuesday)
        // Cadence: Weekly
        // Jan 1 -> Jan 8 (Sun) -> Jan 15 (Sun)
        // Expected: Jan 15

        let calendar = Calendar.current
        let startDateFixed = calendar.date(from: DateComponents(year: 2023, month: 1, day: 1))!
        let referenceDate = calendar.date(from: DateComponents(year: 2023, month: 1, day: 10))!

        let result = BillingCalculator.calculateNextBillingDate(startDate: startDateFixed, cadence: .weekly, referenceDate: referenceDate)

        let expected = calendar.date(from: DateComponents(year: 2023, month: 1, day: 15))!
        XCTAssertEqual(result, expected)
    }

    func testCalculateNextBillingDate_CustomDays() {
        // Start: Jan 1, 2023
        // Reference: Jan 5, 2023
        // Cadence: 3 Days
        // Jan 1 -> Jan 4 -> Jan 7
        // Expected: Jan 7

        let calendar = Calendar.current
        let startDateFixed = calendar.date(from: DateComponents(year: 2023, month: 1, day: 1))!
        let referenceDate = calendar.date(from: DateComponents(year: 2023, month: 1, day: 5))!

        let result = BillingCalculator.calculateNextBillingDate(startDate: startDateFixed, cadence: .customDays(3), referenceDate: referenceDate)

        let expected = calendar.date(from: DateComponents(year: 2023, month: 1, day: 7))!
        XCTAssertEqual(result, expected)
    }

    func testUserRequestedScenarios() {
        let calendar = Calendar.current

        // Scenario 1: Invoice Date 3 Sep 2025 (Future relative to now? Or arbitrary?)
        // Let's assume Reference Date is Oct 15, 2025 to make Sep 3 a "past" invoice.
        let referenceDate = calendar.date(from: DateComponents(year: 2025, month: 10, day: 15))!

        // Case A: 3 Sep 2025, Monthly.
        // Sep 3 -> Oct 3 (Past Ref) -> Nov 3 (Future Ref)
        let sep3 = calendar.date(from: DateComponents(year: 2025, month: 9, day: 3))!
        let resultA = BillingCalculator.calculateNextBillingDate(startDate: sep3, cadence: .monthly, referenceDate: referenceDate)
        let expectedA = calendar.date(from: DateComponents(year: 2025, month: 11, day: 3))!
        XCTAssertEqual(resultA, expectedA, "Monthly: Sep 3 -> Nov 3 (skipping Oct 3 which is < Oct 15)")

        // Case B: 30 Aug 2024, Yearly.
        // Aug 30 2024 -> Aug 30 2025 (< Oct 15 2025) -> Aug 30 2026
        let aug30_24 = calendar.date(from: DateComponents(year: 2024, month: 8, day: 30))!
        let resultB = BillingCalculator.calculateNextBillingDate(startDate: aug30_24, cadence: .yearly, referenceDate: referenceDate)
        let expectedB = calendar.date(from: DateComponents(year: 2026, month: 8, day: 30))!
        XCTAssertEqual(resultB, expectedB, "Yearly: Aug 30 2024 -> Aug 30 2026")

        // Case C: Weekly, Past Date of Previous Week
        // Ref: Oct 15, 2025 (Wednesday)
        // Start: Oct 1, 2025 (Wednesday) -> 2 weeks ago
        // Oct 1 -> Oct 8 -> Oct 15 (Today) -> Oct 22 (Next)
        // Note: Logic says "Start Date > Reference" returns Start.
        // Logic says loop while nextDate <= referenceDate.
        // So if nextDate is Oct 15 and Ref is Oct 15, it loops again.
        // Next is Oct 22.
        let oct1 = calendar.date(from: DateComponents(year: 2025, month: 10, day: 1))!
        let resultC = BillingCalculator.calculateNextBillingDate(startDate: oct1, cadence: .weekly, referenceDate: referenceDate)
        let expectedC = calendar.date(from: DateComponents(year: 2025, month: 10, day: 22))!
        XCTAssertEqual(resultC, expectedC, "Weekly: Oct 1 -> Oct 22 (Skipping Today Oct 15)")
    }

    func testClampingLogic_EndOfMonth() {
        let calendar = Calendar.current

        // Reference: Feb 15, 2025
        let referenceDate = calendar.date(from: DateComponents(year: 2025, month: 2, day: 15))!

        // Start: Jan 31, 2025
        // Jan 31 -> Feb 28 (Clamped)
        // Feb 28 > Feb 15? Yes.
        // Expect: Feb 28, 2025.
        let jan31 = calendar.date(from: DateComponents(year: 2025, month: 1, day: 31))!
        let result = BillingCalculator.calculateNextBillingDate(startDate: jan31, cadence: .monthly, referenceDate: referenceDate)
        let expected = calendar.date(from: DateComponents(year: 2025, month: 2, day: 28))!
        XCTAssertEqual(result, expected, "Clamping: Jan 31 -> Feb 28")
    }

    func testClampingLogic_LeapYear() {
        let calendar = Calendar.current

        // Reference: Feb 15, 2024 (Leap Year)
        let referenceDate = calendar.date(from: DateComponents(year: 2024, month: 2, day: 15))!

        // Start: Jan 31, 2024
        // Jan 31 -> Feb 29 (Leap Clamped)
        // Feb 29 > Feb 15.

        let jan31 = calendar.date(from: DateComponents(year: 2024, month: 1, day: 31))!
        let result = BillingCalculator.calculateNextBillingDate(startDate: jan31, cadence: .monthly, referenceDate: referenceDate)
        let expected = calendar.date(from: DateComponents(year: 2024, month: 2, day: 29))!
        XCTAssertEqual(result, expected, "Clamping: Jan 31 -> Feb 29 (Leap Year)")
    }
}
