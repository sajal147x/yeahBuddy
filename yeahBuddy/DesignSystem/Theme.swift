import SwiftUI

// Design tokens. Views use these instead of raw numbers or colors.

enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
}

enum Radius {
    static let tile: CGFloat = 22
    static let control: CGFloat = 14
}

extension Color {
    /// Page background: true black in dark mode, like a scoreboard.
    static let canvas = Color(light: UIColor(white: 0.95, alpha: 1), dark: .black)
    /// Tile surface sitting on the canvas.
    static let surface = Color(light: .white, dark: UIColor(white: 0.11, alpha: 1))
    /// Controls placed on a tile.
    static let surfaceRaised = Color(light: UIColor(white: 0.92, alpha: 1), dark: UIColor(white: 0.18, alpha: 1))
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary

    private init(light: UIColor, dark: UIColor) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }
}

extension Font {
    /// Hero numbers, e.g. the rest countdown.
    static let scoreHero = Font.system(size: 64, weight: .heavy, design: .rounded).monospacedDigit()
    /// Tile numbers, e.g. volume or set count.
    static let score = Font.system(size: 32, weight: .bold, design: .rounded).monospacedDigit()
    /// Numbers inside rows, e.g. a logged set.
    static let scoreSmall = Font.system(size: 20, weight: .semibold, design: .rounded).monospacedDigit()
    static let tileTitle = Font.system(.title3, design: .rounded).weight(.bold)
    /// Small uppercase labels under numbers.
    static let tileLabel = Font.system(.caption, design: .rounded).weight(.semibold)
}
