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
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: opacity
        )
    }
}

// Semantic colors
public extension Color {
    static let terityText = Color(hex: 0xEF5DA8)
    static let primaryText = Color(hex: 0x423F51)
    static let inverseText = Color(hex: 0xFFFFFF)
    static let secondaryText = Color(hex: 0xA19FA8)
    static let secondarySubTitleText = Color(hex: 0xD0CFD4)
    static let SmartSubscriptionMainStart = Color(hex: 0x00D4F6)
    static let SmartSubscriptionMainEnd = Color(hex: 0x57F1B3)
    static let SmartSubscriptionMainGradient = LinearGradient(
        colors: [
            .SmartSubscriptionMainStart,
            .SmartSubscriptionMainEnd
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
            Color(hex: 0x0055D4).opacity(0.0)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
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
