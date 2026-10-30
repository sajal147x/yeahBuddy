import SwiftUI

/// The rest-between-sets card: a big countdown with +15s and Skip chips.
/// Takes plain values and callbacks; the caller decides how often to redraw it.
struct RestCountdown: View {
    /// Seconds of rest left.
    let remaining: TimeInterval
    /// The full length of this rest including every +15s, shown small next to the label.
    let total: TimeInterval
    /// Called when the user taps +15s.
    let onExtend: () -> Void
    /// Called when the user taps Skip.
    let onSkip: () -> Void

    /// The label and countdown on the left, the two chips stacked on the right.
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: Spacing.xs) {
                    Text("Rest")
                        .font(.label.weight(.semibold))
                        .foregroundStyle(Color.brand)
                    // Muted so it reads as context, not a second countdown.
                    Text("of \(clockText(total))")
                        .font(.label)
                        .foregroundStyle(Color.textSecondary)
                        .contentTransition(.numericText())
                }
                // Round up so the display shows 0:01 until the rest has fully ended,
                // rather than 0:00 for the last second.
                Text(clockText(remaining.rounded(.up)))
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
        .animation(.snappy, value: total)
    }

    /// Formats seconds as a minutes-and-seconds clock, e.g. 105 → "1:45".
    ///
    /// - Parameter seconds: A whole number of seconds.
    /// - Returns: The time as m:ss.
    private func clockText(_ seconds: TimeInterval) -> String {
        Duration.seconds(seconds).formatted(.time(pattern: .minuteSecond))
    }
}

#Preview {
    RestCountdown(remaining: 74, total: 105, onExtend: {}, onSkip: {})
        .padding()
        .background(Color.canvas)
}
