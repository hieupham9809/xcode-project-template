import XCTest
@testable import SmartSubscriptionKit

final class SubscriptionTests: XCTestCase {
    func testSubscriptionInitialization() {
        let subscription = Subscription(
            name: "Test Sub",
            amount: Money(amount: 10.0, currencyCode: "USD"),
            cadence: .monthly,
            startDate: Date()
        )
        
        XCTAssertEqual(subscription.name, "Test Sub")
        XCTAssertEqual(subscription.amount.amount, 10.0)
        XCTAssertEqual(subscription.cadence, .monthly)
        XCTAssertEqual(subscription.status, .active)
    }
    
    func testBillingCadenceCodable() throws {
        let weekly = Subscription.BillingCadence.weekly
        let monthly = Subscription.BillingCadence.monthly
        let yearly = Subscription.BillingCadence.yearly
        let custom = Subscription.BillingCadence.customDays(15)
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        // Test Round Trip
        let weeklyData = try encoder.encode(weekly)
        XCTAssertEqual(try decoder.decode(Subscription.BillingCadence.self, from: weeklyData), weekly)
        
        let customData = try encoder.encode(custom)
        XCTAssertEqual(try decoder.decode(Subscription.BillingCadence.self, from: customData), custom)
    }
}
