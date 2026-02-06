import CoreData
import Foundation

@objc(SubscriptionEntity)
final class SubscriptionEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var name: String
    @NSManaged var providerName: String?
    @NSManaged var amount: NSDecimalNumber
    @NSManaged var currencyCode: String
    @NSManaged var cadenceKind: String
    @NSManaged var cadenceCustomDays: Int64
    @NSManaged var startDate: Date
    @NSManaged var nextBillingDate: Date?
    @NSManaged var status: String
    @NSManaged var notes: String?
    @NSManaged var createdAt: Date
    @NSManaged var updatedAt: Date
    @NSManaged var invoices: Set<InvoiceEntity>
}

@objc(InvoiceEntity)
final class InvoiceEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var invoiceDate: Date
    @NSManaged var totalAmount: NSDecimalNumber
    @NSManaged var totalCurrencyCode: String
    @NSManaged var sourceImageURLString: String?
    @NSManaged var ocrText: String?
    @NSManaged var createdAt: Date

    @NSManaged var subscription: SubscriptionEntity
    @NSManaged var lineItems: Set<InvoiceLineItemEntity>
}

@objc(InvoiceLineItemEntity)
final class InvoiceLineItemEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var title: String
    @NSManaged var amount: NSDecimalNumber
    @NSManaged var currencyCode: String

    @NSManaged var invoice: InvoiceEntity
}

