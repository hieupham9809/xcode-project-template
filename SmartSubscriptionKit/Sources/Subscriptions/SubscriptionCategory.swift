import Foundation

public struct SubscriptionCategory: Identifiable, Hashable, Codable, Sendable {
    public struct ID: Hashable, Codable, Sendable, RawRepresentable {
        public var rawValue: UUID

        public init(rawValue: UUID) {
            self.rawValue = rawValue
        }

        public init() {
            self.rawValue = UUID()
        }
    }

    public var id: ID
    public var name: String
    public var colorHex: String       // e.g., "#FF5733" - platform-agnostic
    public var iconName: String       // SF Symbol name
    public var sortOrder: Int         // For custom ordering (drag-to-reorder)
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: ID = ID(),
        name: String,
        colorHex: String,
        iconName: String,
        sortOrder: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.iconName = iconName
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // Predefined categories (seeded on first launch)
    public static let defaultCategories: [SubscriptionCategory] = [
        SubscriptionCategory(name: "Entertainment", colorHex: "#FF6B6B", iconName: "tv", sortOrder: 0),
        SubscriptionCategory(name: "Productivity", colorHex: "#4ECDC4", iconName: "laptopcomputer", sortOrder: 1),
        SubscriptionCategory(name: "Cloud Storage", colorHex: "#45B7D1", iconName: "cloud", sortOrder: 2),
        SubscriptionCategory(name: "Music", colorHex: "#96CEB4", iconName: "music.note", sortOrder: 3),
        SubscriptionCategory(name: "Gaming", colorHex: "#DDA0DD", iconName: "gamecontroller", sortOrder: 4),
        SubscriptionCategory(name: "News & Media", colorHex: "#F7DC6F", iconName: "newspaper", sortOrder: 5),
        SubscriptionCategory(name: "Finance", colorHex: "#82E0AA", iconName: "dollarsign.circle", sortOrder: 6),
        SubscriptionCategory(name: "Other", colorHex: "#BDC3C7", iconName: "ellipsis.circle", sortOrder: 7),
    ]
}
