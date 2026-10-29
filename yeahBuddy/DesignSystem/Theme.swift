import SwiftUI

// Design tokens. Views use these instead of raw numbers or colors, so the whole look can be
// tuned from this one file. The look is inspired by Sumeria: calm mint-gray surfaces, white
// cards, one deep teal brand color, and big left-aligned titles. Every color has a light
// and a dark value and follows the user's selected appearance.

/// A saved appearance choice. System leaves SwiftUI free to follow the phone's setting.
enum AppAppearance: String, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    /// The app-wide override, or no override when following the system.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

/// Spacing steps. Use these for padding and stack spacing instead of literal numbers.
enum Spacing {
    /// 4pt: between a number and its label.
    static let xs: CGFloat = 4
    /// 8pt: between small related items.
    static let sm: CGFloat = 8
    /// 12pt: between items inside a card, and between cards.
    static let md: CGFloat = 12
    /// 16pt: card padding and screen side margins.
    static let lg: CGFloat = 16
    /// 24pt: between major sections.
    static let xl: CGFloat = 24
}

/// Corner radii, always drawn with the continuous (squircle) style.
enum Radius {
    /// Cards.
    static let card: CGFloat = 22
    /// Full-width buttons and text fields.
    static let control: CGFloat = 16
}

/// The soft drop shadow under cards and the tab bar. Visible in light mode only: on the dark
/// background a shadow can't be seen, so dark cards rely on their lighter fill instead.
enum Shadow {
    /// The shadow color; clear in dark mode.
    static let color = Color(light: UIColor(white: 0, alpha: 0.07), dark: .clear)
    /// How soft the shadow is.
    static let radius: CGFloat = 14
    /// How far below the card it sits, so light seems to come from above.
    static let y: CGFloat = 4
}

extension Color {
    /// Page background: pale mint-gray in light mode, deep teal-black in dark.
    static let canvas = Color(light: rgb(0.933, 0.953, 0.949), dark: rgb(0.043, 0.090, 0.086))
    /// Card surface sitting on the canvas.
    static let surface = Color(light: .white, dark: rgb(0.090, 0.145, 0.141))
    /// Controls placed on a card: chips, stepper buttons, search fields.
    static let surfaceRaised = Color(light: rgb(0.886, 0.925, 0.918), dark: rgb(0.133, 0.200, 0.192))
    /// The one brand color: deep teal in light mode, mint in dark mode so it stays readable.
    static let brand = Color(light: rgb(0.055, 0.290, 0.298), dark: rgb(0.498, 0.847, 0.769))
    /// Text and icons drawn on top of `brand`.
    static let onBrand = Color(light: .white, dark: rgb(0.043, 0.090, 0.086))
    /// Fill for secondary buttons: a pale wash of the brand color.
    static let brandSoft = Color(light: rgb(0.788, 0.871, 0.859), dark: rgb(0.118, 0.239, 0.227))
    /// Main text: numbers and titles. A near-black teal rather than pure black.
    static let textPrimary = Color(light: rgb(0.063, 0.141, 0.137), dark: rgb(0.918, 0.949, 0.945))
    /// Supporting text: labels, dates, captions.
    static let textSecondary = Color(light: rgb(0.369, 0.431, 0.424), dark: rgb(0.576, 0.647, 0.635))
    /// Thin separators inside cards.
    static let divider = Color(light: rgb(0.886, 0.914, 0.910), dark: rgb(0.161, 0.224, 0.216))

    /// Creates a color that switches with light and dark mode.
    ///
    /// - Parameters:
    ///   - light: The color in light mode.
    ///   - dark: The color in dark mode.
    init(light: UIColor, dark: UIColor) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }

    /// Shorthand for an opaque sRGB color, to keep the palette above readable.
    ///
    /// - Parameters:
    ///   - red: Red, 0 to 1.
    ///   - green: Green, 0 to 1.
    ///   - blue: Blue, 0 to 1.
    /// - Returns: The color.
    private static func rgb(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat) -> UIColor {
        UIColor(red: red, green: green, blue: blue, alpha: 1)
    }
}

// Sumeria uses a plain grotesk, so fonts use SF Pro's default design (not rounded). Number
// fonts use monospaced digits so values don't jiggle sideways as they change.
extension Font {
    /// Big left-aligned screen titles, e.g. "History".
    static let screenTitle = Font.system(size: 34, weight: .bold)
    /// Card and section titles.
    static let cardTitle = Font.system(.title3, weight: .bold)
    /// Hero numbers, e.g. the rest countdown or the live workout clock.
    static let amountHero = Font.system(size: 56, weight: .bold).monospacedDigit()
    /// Card numbers, e.g. volume or set count.
    static let amount = Font.system(size: 28, weight: .bold).monospacedDigit()
    /// Numbers inside rows, e.g. a logged set.
    static let amountSmall = Font.system(size: 19, weight: .semibold).monospacedDigit()
    /// Small labels under numbers and above sections.
    static let label = Font.system(.footnote, weight: .medium)
    /// Text on chips and small buttons.
    static let chip = Font.system(.subheadline, weight: .semibold)
}
