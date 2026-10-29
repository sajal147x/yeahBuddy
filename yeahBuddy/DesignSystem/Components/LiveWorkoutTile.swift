import SwiftUI

/// The scoreboard tile for a workout in progress: a pulsing LIVE badge and a running clock.
struct LiveWorkoutTile: View {
    let title: String
    let startedAt: Date
    let setCount: Int
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                LiveBadge(tint: tint)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.headline)
                    .foregroundStyle(Color.textSecondary)
            }
            Text(title)
                .font(.tileTitle)
                .lineLimit(1)
            HStack(alignment: .firstTextBaseline) {
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

private struct LiveBadge: View {
    let tint: Color
    @State private var dimmed = false

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
