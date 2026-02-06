import Foundation
import SmartSubscriptionKit

public protocol InvoiceOCRUseCase: Sendable {
    func parseInvoice(from imageURL: URL) async throws -> Invoice
    func parseInvoice(from imageData: Data) async throws -> Invoice
}

public actor AppInvoiceOCRUseCase: InvoiceOCRUseCase {
    private let parser: InvoiceParser

    public init(parser: InvoiceParser) {
        self.parser = parser
    }

    public func parseInvoice(from imageURL: URL) async throws -> Invoice {
        try await parser.parse(imageURL: imageURL)
    }

    public func parseInvoice(from imageData: Data) async throws -> Invoice {
        try await parser.parse(imageData: imageData)
    }
}
