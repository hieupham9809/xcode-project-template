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
        var relativeImagePath: String?
        if let sourceURL = invoice.sourceImageURL {
            do {
                relativeImagePath = try persistImage(from: sourceURL, for: invoice.id)
            } catch {
                print("Failed to persist image: \(error)")
            }
        }

        try await stack.performBackground { context in
            let subscription = try fetchSubscriptionEntity(id: invoice.subscriptionID, in: context)
            let entity = try findOrCreateInvoiceEntity(for: invoice.id, in: context)

            entity.id = invoice.id.rawValue
            entity.invoiceDate = invoice.invoiceDate
            entity.totalAmount = NSDecimalNumber(decimal: invoice.total.amount)
            entity.totalCurrencyCode = invoice.total.currencyCode
            
            // Store relative path (e.g., "Invoices/UUID.jpg")
            // If we failed to persist new image, keep existing path? 
            // Better: if invoice has a NEW url, we persist it and get new relative path.
            // If invoice.sourceImageURL is nil, we clear it.
            if let newPath = relativeImagePath {
                entity.sourceImageURLString = newPath
            } else if invoice.sourceImageURL == nil {
                entity.sourceImageURLString = nil
            }
            // Note: If invoice.sourceImageURL is unchanged (already pointing to Documents), 
            // persistsImage handles it by returning relative path.
            
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

    /// Persists the image to Documents/Invoices and returns the relative path (e.g., "Invoices/uuid.jpg")
    private func persistImage(from sourceURL: URL, for id: Invoice.ID) throws -> String {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw NSError(domain: "InvoiceRepository", code: 1, userInfo: [NSLocalizedDescriptionKey: "Documents directory not found"])
        }

        let invoicesDirectoryName = "Invoices"
        let invoicesDirectory = documentsURL.appendingPathComponent(invoicesDirectoryName, isDirectory: true)
        
        if !fileManager.fileExists(atPath: invoicesDirectory.path) {
            try fileManager.createDirectory(at: invoicesDirectory, withIntermediateDirectories: true)
        }

        let fileName = "\(id.rawValue.uuidString).jpg"
        let destinationURL = invoicesDirectory.appendingPathComponent(fileName)
        let relativePath = "\(invoicesDirectoryName)/\(fileName)"

        // If source is already the destination, return relative path
        if sourceURL.path == destinationURL.path {
            return relativePath
        }

        // Remove existing file at destination if needed
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }

        // Copy item
        try fileManager.copyItem(at: sourceURL, to: destinationURL)
        return relativePath
    }

    public func delete(id: Invoice.ID) async throws {
        try await stack.performBackground { context in
            let request = NSFetchRequest<InvoiceEntity>(entityName: "InvoiceEntity")
            request.fetchLimit = 1
            request.predicate = NSPredicate(format: "id == %@", id.rawValue as CVarArg)
            guard let entity = try context.fetch(request).first else {
                throw InvoiceRepositoryError.invoiceNotFound
            }

            // Cleanup image file using relative path
            if let relativePath = entity.sourceImageURLString {
                let fileManager = FileManager.default
                if let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
                    let fullURL = documentsURL.appendingPathComponent(relativePath)
                    try? fileManager.removeItem(at: fullURL)
                }
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

        // Resolve relative path to full URL
        var sourceImageURL: URL?
        if let relativePath = sourceImageURLString {
            if let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                sourceImageURL = documentsURL.appendingPathComponent(relativePath)
            }
        }

        return Invoice(
            id: .init(rawValue: id),
            subscriptionID: .init(rawValue: subscription.id),
            invoiceDate: invoiceDate,
            total: Money(amount: totalAmount.decimalValue, currencyCode: totalCurrencyCode),
            lineItems: lineItems,
            sourceImageURL: sourceImageURL,
            ocrText: ocrText,
            createdAt: createdAt
        )
    }
}

