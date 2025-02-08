//
//  View+Font.swift
//
//
//  Created by Harley Pham on 11/8/24.
//

import SwiftUI
import AppKit

public struct FontWithPaddingModifier: ViewModifier {
    let font: NSFont
    let padding: CGFloat?
    
    var fontLineHeight: CGFloat {
        font.ascender - font.descender + font.leading
    }
    private var additionalPadding: CGFloat {
        padding.map { $0 - (fontLineHeight - font.pointSize) / 2 } ?? 0
    }

    public func body(content: Content) -> some View {
        content
            .font(Font(font))
            .padding(.vertical, additionalPadding)
            .lineSpacing(2 * additionalPadding)
    }
}

extension View {
    public func fontWithPadding(_ font: NSFont, padding: CGFloat? = nil) -> some View {
        modifier(FontWithPaddingModifier(font: font, padding: padding))
    }
}
