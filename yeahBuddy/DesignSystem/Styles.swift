import SwiftUI

/// The tile look every card shares: a rounded surface with an optional color wash
/// fading in from the top-left corner.
struct TileModifier: ViewModifier {
    var tint: Color?

    func body(content: Content) -> some View {
        content
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: Radius.tile, style: .continuous)
                    .fill(Color.surface)
                    .overlay {
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
    func tile(tint: Color? = nil) -> some View {
        modifier(TileModifier(tint: tint))
    }
}

/// A full-width, high-contrast button for the main action on a screen.
struct PrimaryButtonStyle: ButtonStyle {
    var tint: Color = .accentColor

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded).weight(.bold))
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(tint, in: RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

/// A full-width button for secondary actions, sitting on the surface color.
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded).weight(.semibold))
            .foregroundStyle(Color.textPrimary)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(Color.surfaceRaised, in: RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }

    static func primary(tint: Color) -> PrimaryButtonStyle {
        PrimaryButtonStyle(tint: tint)
    }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}
