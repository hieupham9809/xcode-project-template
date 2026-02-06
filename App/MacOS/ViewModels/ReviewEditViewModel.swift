import Foundation
import SmartSubscriptionKit
import Combine

@MainActor
final class ReviewEditViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var amount: Decimal = 0.0
    @Published var currencyCode: String = "USD"
    @Published var selectedCadence: SmartSubscriptionKit.Subscription.BillingCadence = .monthly
    @Published var nextBillingDate: Date = Date()
    @Published var providerName: String = ""
    @Published var notes: String = ""
    @Published var lineItems: [SmartSubscriptionKit.Invoice.LineItem] = []
    
    @Published var isValid: Bool = false
    @Published var isSaving: Bool = false
    @Published var saveError: String?
    @Published var shouldDismiss: Bool = false

    private let subscriptionUseCase: SubscriptionUseCase
    private let invoiceRepository: InvoiceRepository?
    private var originalInvoice: Invoice?
    private var existingSubscription: SmartSubscriptionKit.Subscription?
    private let logger = Log.initialize(category: .main)
    private var cancellables = Set<AnyCancellable>()
    private var referenceStartDate: Date = Date()

    init(
        subscriptionUseCase: SubscriptionUseCase,
        invoiceRepository: InvoiceRepository? = nil,
        invoice: Invoice? = nil,
        subscription: SmartSubscriptionKit.Subscription? = nil
    ) {
        self.subscriptionUseCase = subscriptionUseCase
        self.invoiceRepository = invoiceRepository
        self.originalInvoice = invoice
        self.existingSubscription = subscription
        
        if let subscription = subscription {
            self.referenceStartDate = subscription.startDate
        } else if let invoice = invoice {
            self.referenceStartDate = invoice.invoiceDate
        } else {
            self.referenceStartDate = Date()
        }
        
        if let invoice = invoice {
            // Pre-fill from invoice
            self.amount = invoice.total.amount
            self.currencyCode = invoice.total.currencyCode
            self.nextBillingDate = invoice.invoiceDate // Default to invoice date, user adjusts
            self.lineItems = invoice.lineItems
            
            // Try to extract provider name from OCR text (stored as JSON)
            if let rawText = invoice.ocrText {
                logger.debug("[ReviewEditVM] ocrText: \(rawText)")
                self.extractProviderFromOCRText(rawText)
            }
        } else if let subscription = subscription {
            // Pre-fill from existing subscription
            self.name = subscription.name
            self.amount = subscription.amount.amount
            self.currencyCode = subscription.amount.currencyCode
            self.selectedCadence = subscription.cadence
            self.nextBillingDate = subscription.nextBillingDate ?? Date()
            self.providerName = subscription.providerName ?? ""
            self.notes = subscription.notes ?? ""
        }
        validate()
        setupBindings()
    }
    
    private func extractProviderFromOCRText(_ rawText: String) {
        // The ocrText is a JSON string from OpenAIVisionParser
        struct ParsedOCR: Decodable {
            let providerName: String?
            let nextBillingDate: String?
            struct LineItem: Decodable {
                let title: String
                let amount: Decimal
            }
            let lineItems: [LineItem]?
        }
        
        guard let jsonData = rawText.data(using: .utf8) else {
            logger.debug("[ReviewEditVM] Failed to convert ocrText to data")
            return
        }
        
        do {
            let parsed = try JSONDecoder().decode(ParsedOCR.self, from: jsonData)
            if let provider = parsed.providerName {
                logger.debug("[ReviewEditVM] Extracted providerName: \(provider)")
                self.name = provider
                self.providerName = provider
            }
            if let dateString = parsed.nextBillingDate {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                if let date = formatter.date(from: dateString) {
                    logger.debug("[ReviewEditVM] Extracted nextBillingDate: \(dateString)")
                    self.nextBillingDate = date
                }
            }
            
            // Parse line items if invoice.lineItems was empty (fallback)
            if self.lineItems.isEmpty, let items = parsed.lineItems {
                self.lineItems = items.map { 
                    SmartSubscriptionKit.Invoice.LineItem(title: $0.title, amount: Money(amount: $0.amount, currencyCode: self.currencyCode))
                }
            }
        } catch {
            logger.debug("[ReviewEditVM] Failed to parse ocrText as JSON: \(error)")
            // Fallback: Try first line if not JSON (legacy format)
            let lines = rawText.components(separatedBy: .newlines)
            if let first = lines.first, !first.hasPrefix("{") {
                self.name = String(first.prefix(50))
                self.providerName = self.name
            }
        }
    }

    func validate() {
        isValid = !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && amount > 0
    }

    func save() async {
        isSaving = true
        saveError = nil
        
        // If editing, preserve ID and start date
        let id = existingSubscription?.id ?? SmartSubscriptionKit.Subscription.ID()
        let startDate = existingSubscription?.startDate ?? Date()
        
        let subscription = SmartSubscriptionKit.Subscription(
            id: id,
            name: name,
            providerName: providerName.isEmpty ? nil : providerName,
            amount: Money(amount: amount, currencyCode: currencyCode),
            cadence: selectedCadence,
            startDate: startDate,
            nextBillingDate: nextBillingDate,
            status: .active,
            notes: notes.isEmpty ? nil : notes,
            createdAt: existingSubscription?.createdAt ?? Date(),
            updatedAt: Date()
        )
        
        do {
            if existingSubscription != nil {
                try await subscriptionUseCase.updateSubscription(subscription)
            } else {
                try await subscriptionUseCase.addSubscription(subscription)
            }
            
            // If we have an original invoice (from OCR), save it associated with this subscription
            if var invoice = originalInvoice, let repo = invoiceRepository {
                invoice.subscriptionID = subscription.id
                // Update line items in case they were parsed differently or if we want to ensure consistency
                invoice.lineItems = self.lineItems
                try await repo.save(invoice)
                logger.debug("[ReviewEditVM] Saved invoice with \(invoice.lineItems.count) line items")
            }
            
            shouldDismiss = true
        } catch {
            saveError = error.localizedDescription
        }
        isSaving = false
    }

    private func setupBindings() {
        $selectedCadence
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] newCadence in
                guard let self = self else { return }
                self.recalculateNextBilling(cadence: newCadence)
            }
            .store(in: &cancellables)
    }

    private func recalculateNextBilling(cadence: SmartSubscriptionKit.Subscription.BillingCadence) {
        self.nextBillingDate = BillingCalculator.calculateNextBillingDate(
            startDate: self.referenceStartDate,
            cadence: cadence
        )
    }
}
