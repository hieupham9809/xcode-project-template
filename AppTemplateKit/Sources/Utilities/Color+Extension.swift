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
    static let AppTemplateMainStart = Color(hex: 0x00D4F6)
    static let AppTemplateMainEnd = Color(hex: 0x57F1B3)
    static let AppTemplateMainGradient = LinearGradient(
        colors: [
            .AppTemplateMainStart,
            .AppTemplateMainEnd
        ],
        startPoint: .bottomLeading,
        endPoint: .topTrailing
    )
    static let AppTemplateSecondaryGradient = LinearGradient(
        colors: [Color(hex: 0xCDFBE4), Color(hex: 0xC0FAFF)],
        startPoint: .bottomLeading,
        endPoint: .topTrailing
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
