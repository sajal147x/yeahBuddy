import SwiftUI

/// The rest-between-sets tile: a big countdown with +15s and Skip.
struct RestCountdown: View {
    let remaining: TimeInterval
    let onExtend: () -> Void
    let onSkip: () -> Void

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("REST")
                    .font(.tileLabel)
                    .foregroundStyle(Color.textSecondary)
                Text(Duration.seconds(remaining.rounded(.up)).formatted(.time(pattern: .minuteSecond)))
                    .font(.scoreHero)
                    .contentTransition(.numericText(countsDown: true))
            }
            Spacer()
            VStack(spacing: Spacing.sm) {
                Button("+15s", action: onExtend)
                Button("Skip", action: onSkip)
            }
            .font(.system(.subheadline, design: .rounded).weight(.bold))
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
        }
        .tile(tint: .accentColor)
    }
}

#Preview {
    RestCountdown(remaining: 74, onExtend: {}, onSkip: {})
        .padding()
        .background(Color.canvas)
}
