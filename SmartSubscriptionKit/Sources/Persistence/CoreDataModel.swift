import CoreData
import Foundation

enum CoreDataModelFactory {
    static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        let subscription = NSEntityDescription()
        subscription.name = "SubscriptionEntity"
        subscription.managedObjectClassName = NSStringFromClass(SubscriptionEntity.self)
        subscription.properties = [
            uuidAttribute(name: "id"),
            stringAttribute(name: "name"),
            stringAttribute(name: "providerName", isOptional: true),
            decimalAttribute(name: "amount"),
            stringAttribute(name: "currencyCode"),
            stringAttribute(name: "cadenceKind"),
            int64Attribute(name: "cadenceCustomDays"),
            dateAttribute(name: "startDate"),
            dateAttribute(name: "nextBillingDate", isOptional: true),
            stringAttribute(name: "status"),
            stringAttribute(name: "notes", isOptional: true),
            dateAttribute(name: "createdAt"),
            dateAttribute(name: "updatedAt"),
        ]
        subscription.uniquenessConstraints = [["id"]]

        let invoice = NSEntityDescription()
        invoice.name = "InvoiceEntity"
        invoice.managedObjectClassName = NSStringFromClass(InvoiceEntity.self)
        invoice.properties = [
            uuidAttribute(name: "id"),
            dateAttribute(name: "invoiceDate"),
            decimalAttribute(name: "totalAmount"),
            stringAttribute(name: "totalCurrencyCode"),
            stringAttribute(name: "sourceImageURLString", isOptional: true),
            stringAttribute(name: "ocrText", isOptional: true),
            dateAttribute(name: "createdAt"),
        ]
        invoice.uniquenessConstraints = [["id"]]

        let lineItem = NSEntityDescription()
        lineItem.name = "InvoiceLineItemEntity"
        lineItem.managedObjectClassName = NSStringFromClass(InvoiceLineItemEntity.self)
        lineItem.properties = [
            uuidAttribute(name: "id"),
            stringAttribute(name: "title"),
            decimalAttribute(name: "amount"),
            stringAttribute(name: "currencyCode"),
        ]
        lineItem.uniquenessConstraints = [["id"]]

        let subscriptionToInvoices = NSRelationshipDescription()
        subscriptionToInvoices.name = "invoices"
        subscriptionToInvoices.destinationEntity = invoice
        subscriptionToInvoices.minCount = 0
        subscriptionToInvoices.maxCount = 0
        subscriptionToInvoices.deleteRule = .cascadeDeleteRule
        subscriptionToInvoices.isOptional = false
        subscriptionToInvoices.isOrdered = false

        let invoiceToSubscription = NSRelationshipDescription()
        invoiceToSubscription.name = "subscription"
        invoiceToSubscription.destinationEntity = subscription
        invoiceToSubscription.minCount = 1
        invoiceToSubscription.maxCount = 1
        invoiceToSubscription.deleteRule = .nullifyDeleteRule
        invoiceToSubscription.isOptional = false

        subscriptionToInvoices.inverseRelationship = invoiceToSubscription
        invoiceToSubscription.inverseRelationship = subscriptionToInvoices
        subscription.properties.append(subscriptionToInvoices)
        invoice.properties.append(invoiceToSubscription)

        let invoiceToLineItems = NSRelationshipDescription()
        invoiceToLineItems.name = "lineItems"
        invoiceToLineItems.destinationEntity = lineItem
        invoiceToLineItems.minCount = 0
        invoiceToLineItems.maxCount = 0
        invoiceToLineItems.deleteRule = .cascadeDeleteRule
        invoiceToLineItems.isOptional = false
        invoiceToLineItems.isOrdered = false

        let lineItemToInvoice = NSRelationshipDescription()
        lineItemToInvoice.name = "invoice"
        lineItemToInvoice.destinationEntity = invoice
        lineItemToInvoice.minCount = 1
        lineItemToInvoice.maxCount = 1
        lineItemToInvoice.deleteRule = .nullifyDeleteRule
        lineItemToInvoice.isOptional = false

        invoiceToLineItems.inverseRelationship = lineItemToInvoice
        lineItemToInvoice.inverseRelationship = invoiceToLineItems
        invoice.properties.append(invoiceToLineItems)
        lineItem.properties.append(lineItemToInvoice)

        // CategoryEntity definition
        let category = NSEntityDescription()
        category.name = "CategoryEntity"
        category.managedObjectClassName = NSStringFromClass(CategoryEntity.self)
        category.properties = [
            uuidAttribute(name: "id"),
            stringAttribute(name: "name"),
            stringAttribute(name: "colorHex"),
            stringAttribute(name: "iconName"),
            int64Attribute(name: "sortOrder"),
            dateAttribute(name: "createdAt"),
            dateAttribute(name: "updatedAt"),
        ]
        category.uniquenessConstraints = [["id"]]

        // Relationships
        let categoryToSubscriptions = NSRelationshipDescription()
        categoryToSubscriptions.name = "subscriptions"
        categoryToSubscriptions.destinationEntity = subscription
        categoryToSubscriptions.minCount = 0
        categoryToSubscriptions.maxCount = 0 // to-many
        categoryToSubscriptions.deleteRule = .nullifyDeleteRule // Don't cascade delete
        categoryToSubscriptions.isOptional = true

        let subscriptionToCategory = NSRelationshipDescription()
        subscriptionToCategory.name = "category"
        subscriptionToCategory.destinationEntity = category
        subscriptionToCategory.minCount = 0
        subscriptionToCategory.maxCount = 1 // to-one
        subscriptionToCategory.deleteRule = .nullifyDeleteRule
        subscriptionToCategory.isOptional = true

        categoryToSubscriptions.inverseRelationship = subscriptionToCategory
        subscriptionToCategory.inverseRelationship = categoryToSubscriptions

        category.properties.append(categoryToSubscriptions)
        subscription.properties.append(subscriptionToCategory)

        model.entities = [subscription, invoice, lineItem, category]
        return model
    }
}

private func uuidAttribute(name: String) -> NSAttributeDescription {
    let attribute = NSAttributeDescription()
    attribute.name = name
    attribute.attributeType = .UUIDAttributeType
    attribute.isOptional = false
    return attribute
}

private func stringAttribute(name: String, isOptional: Bool = false) -> NSAttributeDescription {
    let attribute = NSAttributeDescription()
    attribute.name = name
    attribute.attributeType = .stringAttributeType
    attribute.isOptional = isOptional
    return attribute
}

private func dateAttribute(name: String, isOptional: Bool = false) -> NSAttributeDescription {
    let attribute = NSAttributeDescription()
    attribute.name = name
    attribute.attributeType = .dateAttributeType
    attribute.isOptional = isOptional
    return attribute
}

private func int64Attribute(name: String) -> NSAttributeDescription {
    let attribute = NSAttributeDescription()
    attribute.name = name
    attribute.attributeType = .integer64AttributeType
    attribute.isOptional = false
    return attribute
}

private func decimalAttribute(name: String) -> NSAttributeDescription {
    let attribute = NSAttributeDescription()
    attribute.name = name
    attribute.attributeType = .decimalAttributeType
    attribute.isOptional = false
    return attribute
}
