import SwiftUI

/// A finished workout in a list: title, date line, the muscles trained, and its totals.
/// Takes plain values so it can be previewed and reused without a database.
struct WorkoutCard: View {
    /// The workout's name, e.g. "Chest · Arms".
    let title: String
    /// The supporting line, e.g. "Tue, Oct 28 · 52 min".
    let subtitle: String
    /// The muscle groups trained, shown as small colored tags.
    let muscles: [MuscleGroup]
    /// The totals along the bottom, left to right.
    let stats: [StatValue]

    /// Title block, muscle tags, a divider, then the totals.
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(.cardTitle)
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
            }
            if !muscles.isEmpty {
                HStack(spacing: Spacing.md) {
                    ForEach(muscles) { MuscleTag(muscle: $0) }
                }
            }
            Divider().overlay(Color.divider)
            HStack(alignment: .top) {
                ForEach(stats) { Stat($0, size: 20) }
            }
        }
        .card()
    }
}

#Preview {
    WorkoutCard(
        title: "Chest · Arms",
        subtitle: "Tue, Oct 28 · 52 min",
        muscles: [.chest, .arms],
        stats: [
            StatValue(number: "4,820", unit: "kg", label: "Volume"),
            StatValue(number: "14", label: "Sets"),
            StatValue(number: "4", label: "Exercises"),
        ]
    )
    .padding()
    .background(Color.canvas)
}
