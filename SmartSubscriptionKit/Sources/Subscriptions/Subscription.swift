import Foundation

public struct Subscription: Identifiable, Hashable, Codable, Sendable {
    public struct ID: Hashable, Codable, Sendable, RawRepresentable {
        public var rawValue: UUID

        public init(rawValue: UUID) {
            self.rawValue = rawValue
        }

        public init() {
            self.rawValue = UUID()
        }
    }

    public enum Status: String, Codable, Hashable, Sendable {
        case active
        case paused
        case cancelled
    }

    public enum BillingCadence: Hashable, Codable, Sendable {
        case weekly
        case monthly
        case yearly
        case customDays(Int)

        private enum CodingKeys: String, CodingKey {
            case kind
            case customDays
        }

        private enum Kind: String, Codable {
            case weekly
            case monthly
            case yearly
            case customDays
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let kind = try container.decode(Kind.self, forKey: .kind)

            switch kind {
            case .weekly:
                self = .weekly
            case .monthly:
                self = .monthly
            case .yearly:
                self = .yearly
            case .customDays:
                self = .customDays(try container.decode(Int.self, forKey: .customDays))
            }
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            switch self {
            case .weekly:
                try container.encode(Kind.weekly, forKey: .kind)
            case .monthly:
                try container.encode(Kind.monthly, forKey: .kind)
            case .yearly:
                try container.encode(Kind.yearly, forKey: .kind)
            case let .customDays(days):
                try container.encode(Kind.customDays, forKey: .kind)
                try container.encode(days, forKey: .customDays)
            }
        }
    }

    public var id: ID
    public var name: String
    public var providerName: String?
    public var amount: Money
    public var cadence: BillingCadence
    public var startDate: Date
    public var nextBillingDate: Date?
    public var status: Status
    public var notes: String?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: ID = ID(),
        name: String,
        providerName: String? = nil,
        amount: Money,
        cadence: BillingCadence,
        startDate: Date,
        nextBillingDate: Date? = nil,
        status: Status = .active,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.providerName = providerName
        self.amount = amount
        self.cadence = cadence
        self.startDate = startDate
        self.nextBillingDate = nextBillingDate
        self.status = status
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

