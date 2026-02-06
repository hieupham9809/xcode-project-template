import Foundation

public struct Invoice: Identifiable, Hashable, Codable, Sendable {
    public struct ID: Hashable, Codable, Sendable, RawRepresentable {
        public var rawValue: UUID

        public init(rawValue: UUID) {
            self.rawValue = rawValue
        }

        public init() {
            self.rawValue = UUID()
        }
    }

    public struct LineItem: Hashable, Codable, Sendable {
        public var title: String
        public var amount: Money

        public init(title: String, amount: Money) {
            self.title = title
            self.amount = amount
        }
    }

    public var id: ID
    public var subscriptionID: Subscription.ID
    public var invoiceDate: Date
    public var total: Money
    public var lineItems: [LineItem]
    public var sourceImageURL: URL?
    public var ocrText: String?
    public var createdAt: Date

    public init(
        id: ID = ID(),
        subscriptionID: Subscription.ID,
        invoiceDate: Date,
        total: Money,
        lineItems: [LineItem] = [],
        sourceImageURL: URL? = nil,
        ocrText: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.subscriptionID = subscriptionID
        self.invoiceDate = invoiceDate
        self.total = total
        self.lineItems = lineItems
        self.sourceImageURL = sourceImageURL
        self.ocrText = ocrText
        self.createdAt = createdAt
    }
}

