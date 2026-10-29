import SwiftUI

// Design tokens. Views use these instead of raw numbers or colors, so the whole look can be
// tuned from this one file.

/// Spacing steps. Use these for padding and stack spacing instead of literal numbers.
enum Spacing {
    /// 4pt: between a number and its label.
    static let xs: CGFloat = 4
    /// 8pt: between small related items.
    static let sm: CGFloat = 8
    /// 12pt: between items inside a tile, and between tiles.
    static let md: CGFloat = 12
    /// 16pt: tile padding and screen side margins.
    static let lg: CGFloat = 16
    /// 24pt: between major sections.
    static let xl: CGFloat = 24
}

/// Corner radii, always drawn with the continuous (squircle) style.
enum Radius {
    /// Tiles and cards.
    static let tile: CGFloat = 22
    /// Buttons and other controls.
    static let control: CGFloat = 14
}

extension Color {
    /// Page background: true black in dark mode, like a scoreboard.
    static let canvas = Color(light: UIColor(white: 0.95, alpha: 1), dark: .black)
    /// Tile surface sitting on the canvas.
    static let surface = Color(light: .white, dark: UIColor(white: 0.11, alpha: 1))
    /// Controls placed on a tile.
    static let surfaceRaised = Color(light: UIColor(white: 0.92, alpha: 1), dark: UIColor(white: 0.18, alpha: 1))
    /// Main text: numbers and titles.
    static let textPrimary = Color.primary
    /// Supporting text: labels, dates, captions.
    static let textSecondary = Color.secondary

    /// Creates a color that switches with light and dark mode.
    ///
    /// The app is dark-only in v1, but the light values are kept so light mode is a
    /// one-line change later.
    ///
    /// - Parameters:
    ///   - light: The color in light mode.
    ///   - dark: The color in dark mode.
    private init(light: UIColor, dark: UIColor) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }
}

// All number fonts use monospaced digits so values don't jiggle sideways as they change
// (e.g. a ticking timer or a stepper going from 19 to 20).
extension Font {
    /// Hero numbers, e.g. the rest countdown.
    static let scoreHero = Font.system(size: 64, weight: .heavy, design: .rounded).monospacedDigit()
    /// Tile numbers, e.g. volume or set count.
    static let score = Font.system(size: 32, weight: .bold, design: .rounded).monospacedDigit()
    /// Numbers inside rows, e.g. a logged set.
    static let scoreSmall = Font.system(size: 20, weight: .semibold, design: .rounded).monospacedDigit()
    /// Tile and section titles.
    static let tileTitle = Font.system(.title3, design: .rounded).weight(.bold)
    /// Small uppercase labels under numbers.
    static let tileLabel = Font.system(.caption, design: .rounded).weight(.semibold)
}
