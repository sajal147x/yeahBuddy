import SwiftUI

/// A grid of colored chips for choosing a muscle group, one per group.
/// The selected chip fills with its muscle color; the others show it as an outline.
struct MuscleChips: View {
    /// The chosen muscle group.
    @Binding var selection: MuscleGroup

    // Three per row fits all six groups in two even rows on any iPhone width.
    private let columns = Array(repeating: GridItem(.flexible(), spacing: Spacing.sm), count: 3)

    /// Two rows of three chips.
    var body: some View {
        LazyVGrid(columns: columns, spacing: Spacing.sm) {
            ForEach(MuscleGroup.allCases) { muscle in
                chip(for: muscle)
            }
        }
    }

    /// One tappable chip.
    ///
    /// - Parameter muscle: The muscle group the chip selects.
    /// - Returns: A capsule button, filled when selected.
    private func chip(for muscle: MuscleGroup) -> some View {
        let isSelected = muscle == selection
        return Button {
            selection = muscle
        } label: {
            Text(muscle.displayName)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                // Black on the bright fill when selected, matching primary buttons.
                .foregroundStyle(isSelected ? Color.black : Color.textPrimary)
                .frame(maxWidth: .infinity, minHeight: 40)
                .background {
                    Capsule()
                        .fill(isSelected ? muscle.tint : Color.surfaceRaised)
                        .overlay {
                            Capsule().strokeBorder(muscle.tint, lineWidth: isSelected ? 0 : 1.5)
                        }
                }
        }
        .buttonStyle(.plain)
        .animation(.snappy, value: isSelected)
    }
}

#Preview {
    @Previewable @State var muscle = MuscleGroup.legs
    MuscleChips(selection: $muscle)
        .tile()
        .padding()
        .background(Color.canvas)
}
