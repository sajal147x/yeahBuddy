import SwiftUI

/// The card for a workout in progress: a pulsing "In progress" label, the workout's name,
/// a big running clock and the set count. Takes plain values so it can be previewed and
/// reused without a database.
struct LiveWorkoutCard: View {
    /// The workout's name, e.g. "Chest · Legs".
    let title: String
    /// When the workout began; the clock counts up from here.
    let startedAt: Date
    /// How many sets have been logged so far.
    let setCount: Int

    /// The status line and chevron, then the title, then the clock beside the set count.
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                LiveLabel()
                Spacer()
                // Hints that the card opens the workout.
                Image(systemName: "chevron.right")
                    .font(.headline)
                    .foregroundStyle(Color.textSecondary)
            }
            Text(title)
                .font(.cardTitle)
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)
            HStack(alignment: .lastTextBaseline) {
                // `.timer` style updates itself every second with no timer code here.
                Text(startedAt, style: .timer)
                    .font(.amountHero)
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Stat(StatValue(number: "\(setCount)", label: "Sets"))
                    .fixedSize()
            }
        }
        .card()
    }
}

/// "In progress" in the brand color with a softly pulsing dot before it.
private struct LiveLabel: View {
    // Toggled once on appear; the repeating animation does the pulsing from then on.
    @State private var dimmed = false

    /// The dot and the words, fading the dot in and out forever.
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color.brand)
                .frame(width: 8, height: 8)
                .opacity(dimmed ? 0.25 : 1)
            Text("In progress")
                .font(.label.weight(.semibold))
                .foregroundStyle(Color.brand)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever()) {
                dimmed = true
            }
        }
    }
}

#Preview {
    LiveWorkoutCard(title: "Chest · Legs", startedAt: .now.addingTimeInterval(-1830), setCount: 9)
        .padding()
        .background(Color.canvas)
}
