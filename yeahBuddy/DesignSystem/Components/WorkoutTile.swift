import SwiftUI

/// A finished workout in a feed: title, date line, and a row of scores.
struct WorkoutTile: View {
    let title: String
    let subtitle: String
    let stats: [(value: String, label: String)]
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(.tileTitle)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
            }
            HStack(alignment: .top) {
                ForEach(stats.indices, id: \.self) { index in
                    Stat(value: stats[index].value, label: stats[index].label, font: .scoreSmall)
                }
            }
        }
        .tile(tint: tint)
    }
}

#Preview {
    WorkoutTile(
        title: "Chest · Arms",
        subtitle: "Tue, Oct 28 · 52 min",
        stats: [("4,820 kg", "Volume"), ("14", "Sets"), ("4", "Exercises")],
        tint: .red
    )
    .padding()
    .background(Color.canvas)
}
