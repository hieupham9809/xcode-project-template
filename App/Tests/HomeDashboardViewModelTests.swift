import Combine
import SmartSubscriptionKit
import XCTest

@MainActor
final class HomeDashboardViewModelTests: XCTestCase {
    var viewModel: HomeDashboardViewModel!
    var mockUseCase: MockSubscriptionUseCase!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        mockUseCase = MockSubscriptionUseCase()
        viewModel = HomeDashboardViewModel(subscriptionUseCase: mockUseCase)
        cancellables = []
    }

    override func tearDown() {
        viewModel = nil
        mockUseCase = nil
        cancellables = nil
        super.tearDown()
    }

    func testLoadSubscriptions_Success() async {
        // Given
        let sub1 = Subscription(name: "Netflix", amount: Money(amount: 15.0, currencyCode: "USD"), cadence: .monthly, startDate: Date())
        let sub2 = Subscription(name: "Spotify", amount: Money(amount: 10.0, currencyCode: "USD"), cadence: .monthly, startDate: Date())
        mockUseCase.subscriptions = [sub1, sub2]

        // When
        await viewModel.loadSubscriptions()

        // Then
        XCTAssertEqual(viewModel.subscriptions.count, 2)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testLoadSubscriptions_Failure() async {
        // Given
        mockUseCase.errorToThrow = NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test Error"])

        // When
        await viewModel.loadSubscriptions()

        // Then
        XCTAssertTrue(viewModel.subscriptions.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, "Failed to load subscriptions: Test Error")
    }

    func testTotalSpend_Calculation() async {
        // Given
        let sub1 = Subscription(name: "Monthly 10", amount: Money(amount: 10.0, currencyCode: "USD"), cadence: .monthly, startDate: Date())
        let sub2 = Subscription(name: "Yearly 120", amount: Money(amount: 120.0, currencyCode: "USD"), cadence: .yearly, startDate: Date())
        mockUseCase.subscriptions = [sub1, sub2]
        await viewModel.loadSubscriptions()

        // Helper to format expected string
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        // The VM uses default locale, so we should too.

        // When (Default Period is Monthly)
        // 10 + (120/12) = 20
        let expectedMonthlyAmount = formatter.string(from: 20.0 as NSDecimalNumber) ?? "$20.00"
        XCTAssertEqual(viewModel.totalSpend, expectedMonthlyAmount + "/mo")

        // When (Period is Yearly)
        viewModel.selectedPeriod = .yearly
        await viewModel.calculateTotalSpend() // Explicitly recalculate after period change
        // (10*12) + 120 = 240
        let expectedYearlyAmount = formatter.string(from: 240.0 as NSDecimalNumber) ?? "$240.00"
        XCTAssertEqual(viewModel.totalSpend, expectedYearlyAmount + "/yr")
    }

    func testDeleteSubscription() async {
        // Given
        let sub1 = Subscription(name: "Delete Me", amount: Money(amount: 5.0, currencyCode: "USD"), cadence: .monthly, startDate: Date())
        mockUseCase.subscriptions = [sub1]
        await viewModel.loadSubscriptions()

        // When
        await viewModel.deleteSubscription(id: sub1.id)

        // Then
        XCTAssertTrue(mockUseCase.deleteCalled)
        XCTAssertTrue(viewModel.subscriptions.isEmpty)
    }
}
