import SwiftUI

/// A large number with − and + buttons, sized for thumbs between sets. Never goes below 0.
struct NumberStepper: View {
    @Binding var value: Double
    let step: Double
    let label: String
    /// Turns the value into the text shown, e.g. "82.5".
    var format: (Double) -> String = { $0.formatted(.number.precision(.fractionLength(0...1))) }

    var body: some View {
        VStack(spacing: Spacing.xs) {
            HStack(spacing: Spacing.xs) {
                stepButton(systemImage: "minus") {
                    value = max(0, value - step)
                }
                Text(format(value))
                    .font(.score)
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

    private func stepButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.title3.weight(.bold))
                .frame(width: 44, height: 44)
                .background(Color.surfaceRaised, in: Circle())
        }
        .buttonStyle(.plain)
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
