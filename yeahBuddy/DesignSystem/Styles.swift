import SwiftUI

/// The card look every panel shares: a padded, rounded surface on a soft shadow.
struct CardModifier: ViewModifier {
    /// Inner padding. Lists inside cards pass a smaller value so rows can run edge to edge.
    var padding: CGFloat = Spacing.lg

    /// Pads the content and draws the card background behind it.
    ///
    /// - Parameter content: The view being styled as a card.
    /// - Returns: The content filling the available width on a rounded card.
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .fill(Color.surface)
                    // Shadow on the background shape only, so text inside stays crisp.
                    .shadow(color: Shadow.color, radius: Shadow.radius, x: 0, y: Shadow.y)
            }
    }
}

extension View {
    /// Styles this view as a card.
    ///
    /// - Parameter padding: Inner padding. Defaults to the standard card padding.
    /// - Returns: The view on a padded, rounded card background.
    func card(padding: CGFloat = Spacing.lg) -> some View {
        modifier(CardModifier(padding: padding))
    }
}

/// A full-width button for the main action on a screen, filled with the brand color.
struct PrimaryButtonStyle: ButtonStyle {
    /// A shorter capsule for actions repeated inside a card (Log Set), so the button doesn't
    /// outweigh the content around it. False is the tall screen-level button.
    var isCompact = false

    /// Draws the label on a brand-colored background that dims while pressed.
    ///
    /// - Parameter configuration: The label and pressed state from SwiftUI.
    /// - Returns: The styled button.
    func makeBody(configuration: Configuration) -> some View {
        if isCompact {
            configuration.label
                .font(.system(.subheadline, weight: .bold))
                .foregroundStyle(Color.onBrand)
                // 44pt: still the minimum comfortable touch target.
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(Color.brand, in: Capsule())
                .opacity(configuration.isPressed ? 0.75 : 1)
        } else {
            configuration.label
                .font(.system(.headline, weight: .bold))
                .foregroundStyle(Color.onBrand)
                // 54pt tall: easy to hit with a thumb between sets.
                .frame(maxWidth: .infinity, minHeight: 54)
                .background(Color.brand, in: RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
                .opacity(configuration.isPressed ? 0.75 : 1)
        }
    }
}

/// A full-width button for secondary actions: brand-colored text on a pale brand wash.
struct SecondaryButtonStyle: ButtonStyle {
    /// Draws the label on a soft brand background that dims while pressed.
    ///
    /// - Parameter configuration: The label and pressed state from SwiftUI.
    /// - Returns: The styled button.
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, weight: .semibold))
            .foregroundStyle(Color.brand)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(Color.brandSoft, in: RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}

/// A small capsule button for quick actions inside cards, e.g. "+15s" or "Skip".
struct ChipButtonStyle: ButtonStyle {
    /// Draws the label on a raised capsule that dims while pressed.
    ///
    /// - Parameter configuration: The label and pressed state from SwiftUI.
    /// - Returns: The styled button.
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.chip)
            .foregroundStyle(Color.textPrimary)
            .padding(.horizontal, 14)
            .frame(minHeight: 34)
            .background(Color.surfaceRaised, in: Capsule())
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}

// Shorthands so call sites read `.buttonStyle(.primary)` like the built-in styles.
extension ButtonStyle where Self == PrimaryButtonStyle {
    /// The primary style.
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }

    /// The primary style as a shorter capsule, for in-card actions like Log Set.
    static var primaryCompact: PrimaryButtonStyle { PrimaryButtonStyle(isCompact: true) }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    /// The secondary style.
    static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}

extension ButtonStyle where Self == ChipButtonStyle {
    /// The chip style.
    static var chip: ChipButtonStyle { ChipButtonStyle() }
}
