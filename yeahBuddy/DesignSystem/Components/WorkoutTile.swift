import SwiftUI

/// A finished workout in a feed: title, date line, and a row of scores.
/// Takes plain values so it can be previewed and reused without a database.
struct WorkoutTile: View {
    /// The workout's name, e.g. "Chest · Arms".
    let title: String
    /// The supporting line, e.g. "Tue, Oct 28 · 52 min".
    let subtitle: String
    /// The scores to show along the bottom, left to right.
    let stats: [(value: String, label: String)]
    /// The tile's color wash.
    let tint: Color

    /// Title and subtitle on top, then the scores in one row.
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
                // Indices as ids: tuples are not Identifiable, and the list never reorders.
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
