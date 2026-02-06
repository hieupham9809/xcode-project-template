import XCTest
import Combine
import SmartSubscriptionKit

@MainActor
final class ReviewEditViewModelTests: XCTestCase {
    var viewModel: ReviewEditViewModel!
    var mockUseCase: MockSubscriptionUseCase!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        mockUseCase = MockSubscriptionUseCase()
        cancellables = []
    }
    
    override func tearDown() {
        viewModel = nil
        mockUseCase = nil
        cancellables = nil
        super.tearDown()
    }

    func testValidation() {
        viewModel = ReviewEditViewModel(subscriptionUseCase: mockUseCase)
        
        // Initial state
        XCTAssertFalse(viewModel.isValid)
        
        // Invalid: Name only
        viewModel.name = "Netflix"
        viewModel.validate()
        XCTAssertFalse(viewModel.isValid)
        
        // Invalid: Amount only
        viewModel.name = ""
        viewModel.amount = 10.0
        viewModel.validate()
        XCTAssertFalse(viewModel.isValid)
        
        // Valid
        viewModel.name = "Netflix"
        viewModel.amount = 10.0
        viewModel.validate()
        XCTAssertTrue(viewModel.isValid)
    }
    
    func testPreFillFromInvoice() {
        let invoice = Invoice(
            subscriptionID: SmartSubscriptionKit.Subscription.ID(),
            invoiceDate: Date(),
            total: Money(amount: 19.99, currencyCode: "USD"),
            ocrText: "Spotify Premium\nMonthly"
        )
        
        viewModel = ReviewEditViewModel(subscriptionUseCase: mockUseCase, invoice: invoice)
        
        XCTAssertEqual(viewModel.amount, 19.99)
        XCTAssertEqual(viewModel.currencyCode, "USD")
        XCTAssertEqual(viewModel.name, "Spotify Premium") // First line
        XCTAssertEqual(viewModel.providerName, "Spotify Premium")
    }
    
    func testPreFillFromSubscription() {
        let sub = Subscription(
            name: "Hulu",
            providerName: "Hulu LLC",
            amount: Money(amount: 12.0, currencyCode: "USD"),
            cadence: .monthly,
            startDate: Date(),
            notes: "My notes"
        )
        
        viewModel = ReviewEditViewModel(subscriptionUseCase: mockUseCase, subscription: sub)
        
        XCTAssertEqual(viewModel.name, "Hulu")
        XCTAssertEqual(viewModel.providerName, "Hulu LLC")
        XCTAssertEqual(viewModel.amount, 12.0)
        XCTAssertEqual(viewModel.notes, "My notes")
        XCTAssertTrue(viewModel.isValid)
    }
    
    func testSave_NewSubscription() async {
        viewModel = ReviewEditViewModel(subscriptionUseCase: mockUseCase)
        viewModel.name = "New Sub"
        viewModel.amount = 5.0
        
        await viewModel.save()
        
        XCTAssertTrue(mockUseCase.addCalled)
        XCTAssertFalse(mockUseCase.updateCalled)
        XCTAssertTrue(viewModel.shouldDismiss)
        XCTAssertEqual(mockUseCase.subscriptions.count, 1)
        XCTAssertEqual(mockUseCase.subscriptions.first?.name, "New Sub")
    }
    
    func testSave_UpdateSubscription() async {
        let sub = Subscription(name: "Old Sub", amount: Money(amount: 5.0, currencyCode: "USD"), cadence: .monthly, startDate: Date())
        mockUseCase.subscriptions = [sub]
        
        viewModel = ReviewEditViewModel(subscriptionUseCase: mockUseCase, subscription: sub)
        viewModel.name = "Updated Sub"
        viewModel.amount = 10.0
        
        await viewModel.save()
        
        XCTAssertTrue(mockUseCase.updateCalled)
        XCTAssertFalse(mockUseCase.addCalled)
        XCTAssertTrue(viewModel.shouldDismiss)
        XCTAssertEqual(mockUseCase.subscriptions.count, 1)
        XCTAssertEqual(mockUseCase.subscriptions.first?.name, "Updated Sub")
        XCTAssertEqual(mockUseCase.subscriptions.first?.amount.amount, 10.0)
    }
}
