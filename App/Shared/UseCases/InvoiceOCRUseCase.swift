import Foundation
import SmartSubscriptionKit

public protocol InvoiceOCRUseCase: Sendable {
    func parseInvoice(from imageURL: URL) async throws -> Invoice
    func parseInvoice(from imageData: Data) async throws -> Invoice
}

public actor AppInvoiceOCRUseCase: InvoiceOCRUseCase {
    private let factory: ParserFactory
    private let settingsStore: SettingsStore
    private let session: URLSession

    public init(
        factory: ParserFactory = ParserFactory(),
        settingsStore: SettingsStore = .shared,
        session: URLSession = .shared
    ) {
        self.factory = factory
        self.settingsStore = settingsStore
        self.session = session
    }

    public func parseInvoice(from imageURL: URL) async throws -> Invoice {
        let parser = factory.createParser(from: settingsStore, session: session)
        return try await parser.parse(imageURL: imageURL)
    }

    public func parseInvoice(from imageData: Data) async throws -> Invoice {
        let parser = factory.createParser(from: settingsStore, session: session)
        return try await parser.parse(imageData: imageData)
    }
}
