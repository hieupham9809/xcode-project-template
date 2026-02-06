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
}
