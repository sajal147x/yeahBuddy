import SwiftUI

/// A large number with − and + buttons, sized for thumbs between sets. Never goes below 0.
struct NumberStepper: View {
    /// The number being edited.
    @Binding var value: Double
    /// How much one tap adds or removes, e.g. 2.5 for kilograms or 1 for reps.
    let step: Double
    /// The caption under the number, e.g. "kg" or "Reps". Shown in uppercase.
    let label: String
    /// Turns the value into the text shown, e.g. "82.5".
    var format: (Double) -> String = { $0.formatted(.number.precision(.fractionLength(0...1))) }

    /// The − button, the number, and the + button in a row, with the label underneath.
    var body: some View {
        VStack(spacing: Spacing.xs) {
            HStack(spacing: Spacing.xs) {
                stepButton(systemImage: "minus") {
                    // Clamp at zero: negative weight or reps are never valid.
                    value = max(0, value - step)
                }
                Text(format(value))
                    .font(.score)
                    // Takes whatever width the buttons leave, so two steppers fit side by
                    // side instead of pushing the tile off screen.
                    .frame(maxWidth: .infinity)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .contentTransition(.numericText(value: value))
                stepButton(systemImage: "plus") {
                    value += step
                }
            }
            Text(label.uppercased())
                .font(.tileLabel)
                .foregroundStyle(Color.textSecondary)
        }
        .animation(.snappy, value: value)
    }

    /// Builds one round − or + button.
    ///
    /// - Parameters:
    ///   - systemImage: The SF Symbol to show, "minus" or "plus".
    ///   - action: What a tap does to `value`.
    /// - Returns: A 44pt circular button, the minimum comfortable touch target.
    private func stepButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.title3.weight(.bold))
                .frame(width: 44, height: 44)
                .background(Color.surfaceRaised, in: Circle())
        }
        .buttonStyle(.plain)
        // Holding the button keeps stepping, so big weight jumps don't need many taps.
        .buttonRepeatBehavior(.enabled)
    }
}

#Preview {
    @Previewable @State var weight = 80.0
    @Previewable @State var reps = 8.0
    HStack {
        NumberStepper(value: $weight, step: 2.5, label: "kg")
        NumberStepper(value: $reps, step: 1, label: "Reps")
    }
    .tile()
    .padding()
    .background(Color.canvas)
}
