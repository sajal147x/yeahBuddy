import SwiftUI

/// A card lit by its muscle group's color: a soft glow from the top-left corner that fades
/// into a dark card surface, after Ultrahuman's cycle-tracking card. Used for exercise
/// cards in the live workout, so each exercise is recognizable by color at a glance.
///
/// The card always uses its dark look, in light mode too: the glow only reads on a dark
/// surface, and the owner wants these cards identical in both appearances.
struct MuscleGlowCard: ViewModifier {
    /// The muscle whose color lights the card; nil draws a plain card.
    let muscle: MuscleGroup?

    // How strong the glow is at its brightest, in the top-left corner.
    private static let peakOpacity = 0.5

    /// The content padded on the glowing surface, with a hairline edge.
    ///
    /// - Parameter content: The card's contents.
    /// - Returns: The content on the lit card.
    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
        return content
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                shape
                    .fill(Color.surface)
                    .overlay {
                        shape.fill(glow)
                    }
                    .shadow(color: Shadow.color, radius: Shadow.radius, x: 0, y: Shadow.y)
            }
            // The edge keeps the card's shape readable where the glow fades into the canvas.
            .overlay(shape.strokeBorder(Color.divider, lineWidth: 1))
            // Resolve every token on and inside the card (surface, text, inset panels, the
            // menu) as dark mode, whatever the app's appearance.
            .environment(\.colorScheme, .dark)
    }

    /// The colored light, strongest in the top-left corner and gone by the far side.
    private var glow: RadialGradient {
        let tint = muscle?.tint ?? .clear
        return RadialGradient(
            colors: [tint.opacity(Self.peakOpacity), tint.opacity(Self.peakOpacity * 0.25), .clear],
            center: .topLeading,
            startRadius: 0,
            endRadius: 340
        )
    }
}

extension View {
    /// Styles this view as a card lit by a muscle group's color.
    ///
    /// - Parameter muscle: The muscle whose color to use; nil for a plain card.
    /// - Returns: The view on the glowing card.
    func muscleGlowCard(_ muscle: MuscleGroup?) -> some View {
        modifier(MuscleGlowCard(muscle: muscle))
    }
}

/// The muscle group as a small uppercase pill, e.g. "CHEST", for the top of a glow card.
struct MusclePill: View {
    /// The muscle group to name.
    let muscle: MuscleGroup

    /// The name in small caps on a translucent capsule with a hairline edge.
    var body: some View {
        Text(muscle.displayName.uppercased())
            .font(.caption2.weight(.semibold))
            .tracking(0.6)
            .foregroundStyle(Color.textPrimary)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, 3)
            .background(Color.inset, in: Capsule())
            .overlay(Capsule().strokeBorder(Color.divider, lineWidth: 1))
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        ForEach([MuscleGroup.chest, .back, .legs], id: \.self) { muscle in
            VStack(spacing: Spacing.sm) {
                MusclePill(muscle: muscle)
                Text("Exercise").font(.cardTitle)
            }
            .frame(maxWidth: .infinity)
            .muscleGlowCard(muscle)
        }
    }
    .padding()
    .background(Color.canvas)
}
