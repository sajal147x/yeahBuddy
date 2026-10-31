import SwiftUI

// Design tokens. Views use these instead of raw numbers or colors, so the whole look can be
// tuned from this one file. The layout is inspired by Sumeria (big left-aligned titles, cards
// with large corners), in plain black and white; the only color is muscle groups. Every color has a light
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

/// The soft drop shadow under cards. Visible in light mode only: on the dark
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
    // The palette is neutral black and white, so the only color on screen is the muscle
    // colors on exercise cards. Light mode is white cards on soft gray; dark mode is
    // charcoal cards on true black.

    /// Page background: soft gray in light mode, black in dark.
    static let canvas = Color(light: rgb(0.949, 0.949, 0.949), dark: rgb(0, 0, 0))
    /// Card surface sitting on the canvas.
    static let surface = Color(light: .white, dark: rgb(0.110, 0.110, 0.118))
    /// Controls placed on a card: chips, stepper buttons, search fields.
    static let surfaceRaised = Color(light: rgb(0.918, 0.918, 0.918), dark: rgb(0.173, 0.173, 0.180))
    /// The primary color: black in light mode, white in dark mode, for the strongest contrast.
    static let brand = Color(light: rgb(0.067, 0.067, 0.067), dark: rgb(0.961, 0.961, 0.961))
    /// Text and icons drawn on top of `brand`.
    static let onBrand = Color(light: .white, dark: .black)
    /// Fill for secondary buttons: a light gray wash, one step above the card.
    static let brandSoft = Color(light: rgb(0.906, 0.906, 0.906), dark: rgb(0.173, 0.173, 0.180))
    /// Main text: numbers and titles. Near-black rather than pure black, to soften it a touch.
    static let textPrimary = Color(light: rgb(0.067, 0.067, 0.067), dark: rgb(0.961, 0.961, 0.961))
    /// Supporting text: labels, dates, captions.
    static let textSecondary = Color(light: rgb(0.431, 0.431, 0.431), dark: rgb(0.596, 0.596, 0.604))
    /// A see-through panel inside a tinted card (done sets, the Add Set button on a glow
    /// card), so the card's color shows through instead of clashing with a solid fill.
    static let inset = Color(light: UIColor(white: 1, alpha: 0.55), dark: UIColor(white: 0, alpha: 0.28))
    /// Thin separators inside cards.
    static let divider = Color(light: rgb(0.898, 0.898, 0.898), dark: rgb(0.188, 0.188, 0.196))

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
    /// Numbers being entered, e.g. the stepper values: a step below `amount` so inputs
    /// don't outweigh the logged sets next to them.
    static let amountInput = Font.system(size: 22, weight: .bold).monospacedDigit()
    /// Numbers inside rows, e.g. a logged set.
    static let amountSmall = Font.system(size: 19, weight: .semibold).monospacedDigit()
    /// Small labels under numbers and above sections.
    static let label = Font.system(.footnote, weight: .medium)
    /// Text on chips and small buttons.
    static let chip = Font.system(.subheadline, weight: .semibold)
}
