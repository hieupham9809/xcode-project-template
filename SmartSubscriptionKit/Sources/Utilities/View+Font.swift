//
//  View+Font.swift
//
//
//  Created by Harley Pham on 11/8/24.
//

import SwiftUI
#if canImport(AppKit)
import AppKit
public typealias PlatformFont = NSFont
#elseif canImport(UIKit)
import UIKit
public typealias PlatformFont = UIFont
#endif

public struct FontWithPaddingModifier: ViewModifier {
    let font: PlatformFont
    let padding: CGFloat?
    
    var fontLineHeight: CGFloat {
        font.ascender - font.descender + font.leading
    }
    private var additionalPadding: CGFloat {
        padding.map { $0 - (fontLineHeight - font.pointSize) / 2 } ?? 0
    }

    public func body(content: Content) -> some View {
        #if os(macOS)
        content
            .font(Font(font))
            .padding(.vertical, additionalPadding)
            .lineSpacing(2 * additionalPadding)
        #else
        content
            .font(Font(font))
            .padding(.vertical, additionalPadding)
            .lineSpacing(2 * additionalPadding)
        #endif
    }
}

extension View {
    public func fontWithPadding(_ font: PlatformFont, padding: CGFloat? = nil) -> some View {
        modifier(FontWithPaddingModifier(font: font, padding: padding))
    }
}
