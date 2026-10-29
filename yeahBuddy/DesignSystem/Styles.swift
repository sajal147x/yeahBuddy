import SwiftUI

/// The tile look every card shares: a rounded surface with an optional color wash
/// fading in from the top-left corner.
struct TileModifier: ViewModifier {
    /// The wash color, usually a muscle group's tint. Nil for a plain tile.
    var tint: Color?

    /// Pads the content and draws the tile background behind it.
    ///
    /// - Parameter content: The view being styled as a tile.
    /// - Returns: The content filling the available width on a rounded tile.
    func body(content: Content) -> some View {
        content
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: Radius.tile, style: .continuous)
                    .fill(Color.surface)
                    .overlay {
                        // The wash fades from 35% to 5% so text stays readable on top.
                        if let tint {
                            RoundedRectangle(cornerRadius: Radius.tile, style: .continuous)
                                .fill(LinearGradient(
                                    colors: [tint.opacity(0.35), tint.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                        }
                    }
            }
    }
}

extension View {
    /// Styles this view as a tile.
    ///
    /// - Parameter tint: An optional color wash, e.g. `muscle.tint`.
    /// - Returns: The view on a padded, rounded tile background.
    func tile(tint: Color? = nil) -> some View {
        modifier(TileModifier(tint: tint))
    }
}

/// A full-width, high-contrast button for the main action on a screen.
struct PrimaryButtonStyle: ButtonStyle {
    /// The button's fill color. Defaults to the app's accent green.
    var tint: Color = .accentColor

    /// Draws the label on a filled, rounded background that dims while pressed.
    ///
    /// - Parameter configuration: The label and pressed state from SwiftUI.
    /// - Returns: The styled button.
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded).weight(.bold))
            // Black text reads best on the bright tints used for primary actions.
            .foregroundStyle(.black)
            // 54pt tall: easy to hit with a thumb between sets.
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(tint, in: RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

/// A full-width button for secondary actions, sitting on the surface color.
struct SecondaryButtonStyle: ButtonStyle {
    /// Draws the label on a raised surface background that dims while pressed.
    ///
    /// - Parameter configuration: The label and pressed state from SwiftUI.
    /// - Returns: The styled button.
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded).weight(.semibold))
            .foregroundStyle(Color.textPrimary)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(Color.surfaceRaised, in: RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

// Shorthands so call sites read `.buttonStyle(.primary)` like the built-in styles.
extension ButtonStyle where Self == PrimaryButtonStyle {
    /// The primary style in the accent color.
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }

    /// The primary style in a given color, e.g. a muscle group's tint.
    ///
    /// - Parameter tint: The fill color.
    /// - Returns: A primary button style using that color.
    static func primary(tint: Color) -> PrimaryButtonStyle {
        PrimaryButtonStyle(tint: tint)
    }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    /// The secondary style.
    static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}
