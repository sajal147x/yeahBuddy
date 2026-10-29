import SwiftUI

/// The scoreboard tile for a workout in progress: a pulsing LIVE badge and a running clock.
/// Takes plain values so it can be previewed and reused without a database.
struct LiveWorkoutTile: View {
    /// The workout's name, e.g. "Chest · Legs".
    let title: String
    /// When the workout began; the clock counts up from here.
    let startedAt: Date
    /// How many sets have been logged so far.
    let setCount: Int
    /// The tile's color wash, usually the first muscle group's tint.
    let tint: Color

    /// The badge and chevron on top, then the title, then the big clock beside the set count.
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                LiveBadge(tint: tint)
                Spacer()
                // Hints that the tile opens the workout.
                Image(systemName: "chevron.right")
                    .font(.headline)
                    .foregroundStyle(Color.textSecondary)
            }
            Text(title)
                .font(.tileTitle)
                .lineLimit(1)
            HStack(alignment: .firstTextBaseline) {
                // `.timer` style updates itself every second with no timer code here.
                Text(startedAt, style: .timer)
                    .font(.scoreHero)
                Spacer()
                Stat(value: "\(setCount)", label: "Sets", font: .score)
                    .fixedSize()
            }
        }
        .tile(tint: tint)
    }
}

/// A small capsule with a pulsing dot and the word LIVE.
private struct LiveBadge: View {
    /// The dot's color.
    let tint: Color
    // Toggled once on appear; the repeating animation does the pulsing from then on.
    @State private var dimmed = false

    /// The dot and label on a capsule, with the dot fading in and out forever.
    var body: some View {
        HStack(spacing: Spacing.xs) {
            Circle()
                .fill(tint)
                .frame(width: 8, height: 8)
                .opacity(dimmed ? 0.3 : 1)
            Text("LIVE")
                .font(.tileLabel)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(Color.surfaceRaised, in: Capsule())
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever()) {
                dimmed = true
            }
        }
    }
}

#Preview {
    LiveWorkoutTile(title: "Chest · Legs", startedAt: .now.addingTimeInterval(-1830), setCount: 9, tint: .red)
        .padding()
        .background(Color.canvas)
}
