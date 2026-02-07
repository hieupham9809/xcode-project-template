import Foundation

public enum InvoiceParserError: Error, Sendable {
    case invalidImage
    case parsingFailed(String)
    case networkError(String)
    case noAPIKey
    case unauthorized
    case rateLimited
    case cancelled
    case ocrFailed(OCRError)
}

public protocol InvoiceParser: Sendable {
    func parse(imageURL: URL) async throws -> Invoice
    func parse(imageData: Data) async throws -> Invoice
}
