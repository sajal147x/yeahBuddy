import SwiftUI

/// The rest-between-sets card: a big countdown with +15s and Skip chips.
/// Takes plain values and callbacks; the caller decides how often to redraw it.
struct RestCountdown: View {
    /// Seconds of rest left.
    let remaining: TimeInterval
    /// Called when the user taps +15s.
    let onExtend: () -> Void
    /// Called when the user taps Skip.
    let onSkip: () -> Void

    /// The label and countdown on the left, the two chips stacked on the right.
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Rest")
                    .font(.label.weight(.semibold))
                    .foregroundStyle(Color.brand)
                // Round up so the display shows 0:01 until the rest has fully ended,
                // rather than 0:00 for the last second.
                Text(Duration.seconds(remaining.rounded(.up)).formatted(.time(pattern: .minuteSecond)))
                    .font(.amountHero)
                    .foregroundStyle(Color.textPrimary)
                    .contentTransition(.numericText(countsDown: true))
            }
            Spacer()
            VStack(spacing: Spacing.sm) {
                Button("+15s", action: onExtend)
                Button("Skip", action: onSkip)
            }
            .buttonStyle(.chip)
        }
        .card()
    }
}

#Preview {
    RestCountdown(remaining: 74, onExtend: {}, onSkip: {})
        .padding()
        .background(Color.canvas)
}
