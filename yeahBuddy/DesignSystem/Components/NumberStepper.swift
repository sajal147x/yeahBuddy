import SwiftUI

/// A large number with − and + buttons, sized for thumbs between sets. Never goes below 0.
///
/// The buttons are for small adjustments; for a big jump, tap the number and type it.
struct NumberStepper: View {
    /// The number being edited.
    @Binding var value: Double
    /// How much one tap adds or removes, e.g. 2.5 for kilograms or 1 for reps.
    let step: Double
    /// The caption under the number, e.g. "kg" or "Reps".
    let label: String
    /// Whether typed values may have a decimal part. False for reps, which also switches the
    /// keyboard to a plain number pad.
    var allowsDecimals = true
    /// Turns the value into the text shown, e.g. "82.5".
    var format: (Double) -> String = { $0.formatted(.number.precision(.fractionLength(0...1))) }

    // Whether the number is being typed. Drives the keyboard via focus.
    @FocusState private var typing: Bool
    // What has been typed so far. Starts empty each time so the user types a fresh number
    // instead of deleting the old one first.
    @State private var draft = ""

    /// The − button, the number, and the + button in a row, with the label underneath.
    var body: some View {
        VStack(spacing: Spacing.xs) {
            HStack(spacing: Spacing.xs) {
                stepButton(systemImage: "minus") {
                    // Clamp at zero: negative weight or reps are never valid.
                    value = max(0, value - step)
                }
                number
                    // Takes whatever width the buttons leave, so two steppers fit side by
                    // side instead of pushing the card off screen.
                    .frame(maxWidth: .infinity)
                stepButton(systemImage: "plus") {
                    value += step
                }
            }
            Text(label)
                .font(.label)
                .foregroundStyle(Color.textSecondary)
        }
        .animation(.snappy, value: value)
        .onChange(of: draft) { _, typed in
            apply(typed)
        }
        .onChange(of: typing) { _, isTyping in
            // Clear on the way in so the field starts empty; the current value shows as the
            // placeholder until the first digit.
            if isTyping {
                draft = ""
            }
        }
        // No Done button here: the number pad has no return key, so the screen hosting the
        // steppers adds one with `.keyboardDoneButton()`. One per screen, because a keyboard
        // toolbar per stepper would show a row of Done buttons, and adding it only while
        // typing never reached the on-screen keyboard.
    }

    /// The big number. Tapping it swaps in a text field with the number pad up.
    ///
    /// Both are always present and swapped by opacity: the field must stay in the hierarchy
    /// for focus to move into it, and keeping the label's size avoids a layout jump.
    private var number: some View {
        ZStack {
            Button {
                typing = true
            } label: {
                // 22pt rather than the 28pt amount size, so the inputs sit below the logged
                // sets in visual weight.
                Text.amount(format(value), size: 22)
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .contentTransition(.numericText(value: value))
                    // Widen the tap target to the whole gap between the buttons.
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(format(value)) \(label)")
            .accessibilityHint("Double tap to type a value")
            .opacity(typing ? 0 : 1)

            TextField("", text: $draft, prompt: Text(format(value)).foregroundStyle(Color.textSecondary))
                .focused($typing)
                .keyboardType(allowsDecimals ? .decimalPad : .numberPad)
                .font(.amountInput)
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.center)
                .tint(Color.brand)
                .opacity(typing ? 1 : 0)
                // While hidden, taps go to the button above instead.
                .allowsHitTesting(typing)
        }
    }

    /// Updates `value` from what has been typed so far, live, so tapping Log Set with the
    /// keyboard still up logs the number on screen rather than the one before.
    ///
    /// Anything that isn't a number yet (an empty field, a lone ".") leaves `value` alone,
    /// so backing out of typing never wipes the old number.
    ///
    /// - Parameter typed: The field's text, in the user's locale (e.g. "82,5" in Germany).
    private func apply(_ typed: String) {
        guard let parsed = try? Double(typed, format: .number) else {
            return
        }
        // Clamp at zero for the same reason as the − button.
        var newValue = max(0, parsed)
        if !allowsDecimals {
            // The number pad has no decimal key, but a pasted "8.5" could still get here.
            newValue = newValue.rounded(.down)
        }
        value = newValue
    }

    /// Builds one round − or + button.
    ///
    /// - Parameters:
    ///   - systemImage: The SF Symbol to show, "minus" or "plus".
    ///   - action: What a tap does to `value`.
    /// - Returns: A 36pt circle inside a 44pt tap area, the minimum comfortable touch target.
    private func stepButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.body.weight(.bold))
                .foregroundStyle(Color.brand)
                .frame(width: 36, height: 36)
                .background(Color.brandSoft, in: Circle())
                // Drawn smaller so it looks quieter, but still easy to hit.
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // Holding the button keeps stepping, so big weight jumps don't need many taps.
        .buttonRepeatBehavior(.enabled)
    }
}

#Preview {
    @Previewable @State var weight = 82.5
    @Previewable @State var reps = 8.0
    HStack {
        NumberStepper(value: $weight, step: 2.5, label: "kg")
        NumberStepper(value: $reps, step: 1, label: "Reps", allowsDecimals: false, format: { "\(Int($0))" })
    }
    .card()
    .padding()
    .background(Color.canvas)
}
