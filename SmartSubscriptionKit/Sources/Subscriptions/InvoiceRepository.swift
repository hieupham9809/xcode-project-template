import CoreData
import Foundation

public enum InvoiceRepositoryError: Error, Sendable, Equatable {
    case invoiceNotFound
    case subscriptionNotFound
}

public protocol InvoiceRepository: Sendable {
    func fetch(id: Invoice.ID) async throws -> Invoice?
    func fetchAll(for subscriptionID: Subscription.ID) async throws -> [Invoice]
    func fetchRecent(limit: Int) async throws -> [Invoice]
    func save(_ invoice: Invoice) async throws
    func delete(id: Invoice.ID) async throws
}

public actor CoreDataInvoiceRepository: InvoiceRepository {
    private let stack: CoreDataStack

    public init(stack: CoreDataStack) {
        self.stack = stack
    }

    public func fetch(id: Invoice.ID) async throws -> Invoice? {
        try await stack.performBackground { context in
            let request = NSFetchRequest<InvoiceEntity>(entityName: "InvoiceEntity")
            request.fetchLimit = 1
            request.predicate = NSPredicate(format: "id == %@", id.rawValue as CVarArg)
            return try context.fetch(request).first?.toDomain()
        }
    }

    public func fetchAll(for subscriptionID: Subscription.ID) async throws -> [Invoice] {
        try await stack.performBackground { context in
            let request = NSFetchRequest<InvoiceEntity>(entityName: "InvoiceEntity")
            request.predicate = NSPredicate(format: "subscription.id == %@", subscriptionID.rawValue as CVarArg)
            request.sortDescriptors = [
                NSSortDescriptor(key: "invoiceDate", ascending: false),
                NSSortDescriptor(key: "createdAt", ascending: false)
            ]
            return try context.fetch(request).map { $0.toDomain() }
        }
    }

    public func fetchRecent(limit: Int) async throws -> [Invoice] {
        try await stack.performBackground { context in
            let request = NSFetchRequest<InvoiceEntity>(entityName: "InvoiceEntity")
            request.fetchLimit = max(0, limit)
            request.sortDescriptors = [
                NSSortDescriptor(key: "invoiceDate", ascending: false),
                NSSortDescriptor(key: "createdAt", ascending: false)
            ]
            return try context.fetch(request).map { $0.toDomain() }
        }
    }

    public func save(_ invoice: Invoice) async throws {
        // Persist image if needed before saving entity
        var persistentImageURL: URL? = invoice.sourceImageURL
        if let sourceURL = invoice.sourceImageURL {
            do {
                persistentImageURL = try persistImage(from: sourceURL, for: invoice.id)
            } catch {
                print("Failed to persist image: \(error)")
                // Fallback to original URL if persistence fails, though it might be temporary
            }
        }

        try await stack.performBackground { context in
            let subscription = try fetchSubscriptionEntity(id: invoice.subscriptionID, in: context)
            let entity = try findOrCreateInvoiceEntity(for: invoice.id, in: context)

            entity.id = invoice.id.rawValue
            entity.invoiceDate = invoice.invoiceDate
            entity.totalAmount = NSDecimalNumber(decimal: invoice.total.amount)
            entity.totalCurrencyCode = invoice.total.currencyCode
            entity.sourceImageURLString = persistentImageURL?.absoluteString // Use persistent URL
            entity.lineItems.forEach { context.delete($0) }
            entity.lineItems.removeAll()
            // ... (rest of usage)
            entity.ocrText = invoice.ocrText
            entity.createdAt = invoice.createdAt
            entity.subscription = subscription

            invoice.lineItems.forEach { item in
                let entityDescription = NSEntityDescription.entity(forEntityName: "InvoiceLineItemEntity", in: context)
                let itemEntity = InvoiceLineItemEntity(entity: entityDescription!, insertInto: context)
                itemEntity.id = UUID()
                itemEntity.title = item.title
                itemEntity.amount = NSDecimalNumber(decimal: item.amount.amount)
                itemEntity.currencyCode = item.amount.currencyCode
                itemEntity.invoice = entity
                entity.lineItems.insert(itemEntity)
            }

            if context.hasChanges {
                try context.save()
            }
        }
    }

    private func persistImage(from sourceURL: URL, for id: Invoice.ID) throws -> URL {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return sourceURL
        }

        let invoicesDirectory = documentsURL.appendingPathComponent("Invoices", isDirectory: true)
        if !fileManager.fileExists(atPath: invoicesDirectory.path) {
            try fileManager.createDirectory(at: invoicesDirectory, withIntermediateDirectories: true)
        }

        let destinationURL = invoicesDirectory.appendingPathComponent("\(id.rawValue.uuidString).jpg")

        // If source is already the destination, return
        if sourceURL.path == destinationURL.path {
            return destinationURL
        }

        // Remove existing file at destination if needed
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }

        // Copy item (copy is safer than move if source is needed elsewhere temporarily)
        try fileManager.copyItem(at: sourceURL, to: destinationURL)
        return destinationURL
    }

    public func delete(id: Invoice.ID) async throws {
        try await stack.performBackground { context in
            let request = NSFetchRequest<InvoiceEntity>(entityName: "InvoiceEntity")
            request.fetchLimit = 1
            request.predicate = NSPredicate(format: "id == %@", id.rawValue as CVarArg)
            guard let entity = try context.fetch(request).first else {
                throw InvoiceRepositoryError.invoiceNotFound
            }

            // Cleanup image file
            if let urlString = entity.sourceImageURLString,
               let url = URL(string: urlString),
               url.path.contains("Documents/Invoices") // Safety check
            {
                try? FileManager.default.removeItem(at: url)
            }

            context.delete(entity)
            if context.hasChanges {
                try context.save()
            }
        }
    }
}

private func fetchSubscriptionEntity(id: Subscription.ID, in context: NSManagedObjectContext) throws -> SubscriptionEntity {
    let request = NSFetchRequest<SubscriptionEntity>(entityName: "SubscriptionEntity")
    request.fetchLimit = 1
    request.predicate = NSPredicate(format: "id == %@", id.rawValue as CVarArg)
    guard let entity = try context.fetch(request).first else {
        throw InvoiceRepositoryError.subscriptionNotFound
    }
    return entity
}

private func findOrCreateInvoiceEntity(for id: Invoice.ID, in context: NSManagedObjectContext) throws -> InvoiceEntity {
    let request = NSFetchRequest<InvoiceEntity>(entityName: "InvoiceEntity")
    request.fetchLimit = 1
    request.predicate = NSPredicate(format: "id == %@", id.rawValue as CVarArg)
    if let existing = try context.fetch(request).first {
        return existing
    }

    let entityDescription = NSEntityDescription.entity(forEntityName: "InvoiceEntity", in: context)
    let entity = InvoiceEntity(entity: entityDescription!, insertInto: context)
    entity.id = id.rawValue
    entity.createdAt = Date()
    return entity
}

private extension InvoiceEntity {
    func toDomain() -> Invoice {
        let lineItems = self.lineItems.map { entity in
            Invoice.LineItem(
                title: entity.title,
                amount: Money(amount: entity.amount.decimalValue, currencyCode: entity.currencyCode)
            )
        }

        return Invoice(
            id: .init(rawValue: id),
            subscriptionID: .init(rawValue: subscription.id),
            invoiceDate: invoiceDate,
            total: Money(amount: totalAmount.decimalValue, currencyCode: totalCurrencyCode),
            lineItems: lineItems,
            sourceImageURL: sourceImageURLString.flatMap(URL.init(string:)),
            ocrText: ocrText,
            createdAt: createdAt
        )
    }
}

