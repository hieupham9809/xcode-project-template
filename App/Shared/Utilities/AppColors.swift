import SwiftUI
import SmartSubscriptionKit

/// Semantic color system for SmartSubscriptions
/// Supports both light and dark modes with adaptive colors
///
/// Usage:
/// ```swift
/// Text("Hello")
///     .foregroundColor(.appPrimaryText)
///
/// Rectangle()
///     .fill(Color.appCardBackground)
/// ```
extension Color {
    // MARK: - Backgrounds

    /// Primary background color for main views
    /// Light: #F2F2F7 (Light Gray)
    /// Dark: #000000 (Pure Black)
    static var appPrimaryBackground: Color {
        Color("AppPrimaryBackground")
    }

    /// Secondary background color for containers and sections
    /// Light: #FFFFFF (White)
    /// Dark: #1C1C1E (Dark Gray)
    static var appSecondaryBackground: Color {
        Color("AppSecondaryBackground")
    }

    /// Card background with subtle elevation
    /// Light: #FFFFFF (White)
    /// Dark: #1C1C1E (Dark Gray)
    static var appCardBackground: Color {
        Color("AppCardBackground")
    }

    /// Elevated surface background (modals, popovers)
    /// Light: #FFFFFF (White)
    /// Dark: #2C2C2E (Slightly lighter gray)
    static var appElevatedBackground: Color {
        Color("AppElevatedBackground")
    }

    // MARK: - Text Colors

    /// Primary text color for main content
    /// Light: #000000 (Black)
    /// Dark: #FFFFFF (White)
    static var appPrimaryText: Color {
        Color("AppPrimaryText")
    }

    /// Secondary text color for labels and metadata
    /// Light: #8E8E93 (Gray)
    /// Dark: #8E8E93 (Gray - same in both modes for consistency)
    static var appSecondaryText: Color {
        Color("AppSecondaryText")
    }

    /// Tertiary text color for disabled or less important text
    /// Light: #C7C7CC (Light Gray)
    /// Dark: #48484A (Dark Gray)
    static var appTertiaryText: Color {
        Color("AppTertiaryText")
    }

    // MARK: - Brand Colors

    /// Primary brand color (Blue)
    /// Light: #0066CC (Brand Blue)
    /// Dark: #0A84FF (Lighter Blue for better contrast)
    static var appBrandPrimary: Color {
        Color("AppBrandPrimary")
    }

    /// Deep blue brand color
    /// Light: #1E3A5F (Deep Blue)
    /// Dark: #4A90D9 (Lighter Blue)
    static var appBrandDeepBlue: Color {
        Color("AppBrandDeepBlue")
    }

    /// Accent color for CTAs and important actions
    /// Light: #F97316 (Orange)
    /// Dark: #FF9500 (iOS Orange)
    static var appAccent: Color {
        Color("AppAccent")
    }

    // MARK: - UI Elements

    /// Border color for cards and dividers
    /// Light: #E2E8F0 (Light Gray)
    /// Dark: #38383A (Dark Gray)
    static var appBorder: Color {
        Color("AppBorder")
    }

    /// Separator color for dividers
    /// Light: #E5E5EA (Very Light Gray)
    /// Dark: #38383A (Dark Gray)
    static var appSeparator: Color {
        Color("AppSeparator")
    }

    /// Shadow color for elevated elements
    /// Light: #000000 with low opacity
    /// Dark: #000000 with very low opacity
    static var appShadow: Color {
        Color("AppShadow")
    }

    // MARK: - Semantic Colors

    /// Success color (green)
    /// Light: #34C759 (iOS Green)
    /// Dark: #32D74B (Lighter Green)
    static var appSuccess: Color {
        Color("AppSuccess")
    }

    /// Error color (red)
    /// Light: #FF3B30 (iOS Red)
    /// Dark: #FF453A (Lighter Red)
    static var appError: Color {
        Color("AppError")
    }

    /// Warning color (yellow)
    /// Light: #FF9500 (iOS Orange)
    /// Dark: #FF9F0A (Lighter Orange)
    static var appWarning: Color {
        Color("AppWarning")
    }

    /// Info color (blue)
    /// Light: #007AFF (iOS Blue)
    /// Dark: #0A84FF (Lighter Blue)
    static var appInfo: Color {
        Color("AppInfo")
    }

    // MARK: - Overlay Colors

    /// Overlay for dimming background (sheets, alerts)
    /// Light: Black with 30% opacity
    /// Dark: Black with 50% opacity
    static var appOverlay: Color {
        Color("AppOverlay")
    }
}

// MARK: - Color Scheme Helpers

extension Color {
    /// Initialize color from hex value with support for dark mode
    /// - Parameters:
    ///   - light: Hex value for light mode (e.g., 0xFFFFFF)
    ///   - dark: Hex value for dark mode (e.g., 0x000000)
    init(light: UInt, dark: UInt) {
        #if os(iOS)
        self.init(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(hex: dark)
                : UIColor(hex: light)
        })
        #elseif os(macOS)
        self.init(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? NSColor(hex: dark)
                : NSColor(hex: light)
        })
        #endif
    }
}

#if os(iOS)
extension UIColor {
    convenience init(hex: UInt, alpha: CGFloat = 1.0) {
        self.init(
            red: CGFloat((hex & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((hex & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(hex & 0x0000FF) / 255.0,
            alpha: alpha
        )
    }
}
#elseif os(macOS)
extension NSColor {
    convenience init(hex: UInt, alpha: CGFloat = 1.0) {
        self.init(
            red: CGFloat((hex & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((hex & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(hex & 0x0000FF) / 255.0,
            alpha: alpha
        )
    }
}
#endif

// MARK: - Appearance Mode Helpers

extension View {
    /// Applies the user's selected appearance mode
    func applyAppearanceMode(_ mode: AppearanceMode) -> some View {
        switch mode {
        case .system:
            return self.preferredColorScheme(nil)
        case .light:
            return self.preferredColorScheme(.light)
        case .dark:
            return self.preferredColorScheme(.dark)
        }
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension View {
    /// Preview view in both light and dark modes
    func previewInBothModes() -> some View {
        Group {
            self
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")

            self
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
}
#endif
