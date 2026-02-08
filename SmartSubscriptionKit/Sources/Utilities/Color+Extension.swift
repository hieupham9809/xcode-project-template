//
//  Color+Extension.swift
//
//
//  Created by Harley Pham on 19/05/2024.
//

import SwiftUI

public extension Color {
    init(hex: Int, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 08) & 0xFF) / 255,
            blue: Double((hex >> 00) & 0xFF) / 255,
            opacity: opacity
        )
    }

    init(hexString: String, opacity: Double = 1) {
        var hex = hexString.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hex.hasPrefix("#") {
            hex.remove(at: hex.startIndex)
        }
        
        // Default to black if invalid
        guard let intCode = Int(hex, radix: 16) else {
            self.init(hex: 0x000000, opacity: opacity)
            return
        }
        
        self.init(hex: intCode, opacity: opacity)
    }
}

// Semantic colors
public extension Color {
    static let terityText = Color(hex: 0xEF5DA8)
    static let primaryText = Color(hex: 0x423F51)
    static let inverseText = Color(hex: 0xFFFFFF)
    static let secondaryText = Color(hex: 0xA19FA8)
    static let secondarySubTitleText = Color(hex: 0xD0CFD4)
    static let SmartSubscriptionMainStart = Color(hex: 0x0055D4)
    static let SmartSubscriptionMainEnd = Color(hex: 0x0055D4).opacity(0.0)
    static let SmartSubscriptionMainGradient = LinearGradient(
        colors: [
            .SmartSubscriptionMainStart,
            .SmartSubscriptionMainEnd,
        ],
        startPoint: .bottomLeading,
        endPoint: .topTrailing
    )
    static let SmartSubscriptionSecondaryGradient = LinearGradient(
        colors: [Color(hex: 0xCDFBE4), Color(hex: 0xC0FAFF)],
        startPoint: .bottomLeading,
        endPoint: .topTrailing
    )

    // Brand Colors from Design
    static let brandDeepBlue = Color(hex: 0x0055D4) // Deep Blue
    static let brandHeaderGradient = LinearGradient(
        colors: [
            Color(hex: 0x0055D4),
            Color(hex: 0x0055D4).opacity(0.8),
            Color(hex: 0x0055D4).opacity(0.3),
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    // Billing Urgency Colors
    static let urgentRed = Color(hex: 0xE53935) // Due within 3 days
    static let warningOrange = Color(hex: 0xFB8C00) // Due within 7 days
    static let safeGreen = Color(hex: 0x43A047) // Due in 7+ days

    var linearGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [self]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

public extension LinearGradient {
    static let clear = LinearGradient(
        colors: [],
        startPoint: .bottomLeading,
        endPoint: .topTrailing
    )
}
