import SwiftUI

/// A finished workout: its totals, then every exercise with its sets.
struct WorkoutDetailView: View {
    /// The workout to show.
    let workout: Workout

    @Environment(WorkoutLog.self) private var log
    @Environment(\.dismiss) private var dismiss
    @AppStorage("weightUnit") private var unit: WeightUnit = .kilograms
    // Whether the "Delete this workout?" dialog is showing.
    @State private var confirmingDelete = false

    /// The totals tile, one tile per exercise, and a Delete button in the toolbar.
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                HStack(alignment: .top) {
                    ForEach(workout.stats(in: unit), id: \.label) { stat in
                        Stat(value: stat.value, label: stat.label, font: .scoreSmall)
                    }
                }
                .tile(tint: workout.tint)
                ForEach(workout.orderedEntries) { entry in
                    entryTile(entry)
                }
            }
            .padding(Spacing.lg)
        }
        .background(Color.canvas)
        .navigationTitle(workout.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("Delete", systemImage: "trash", role: .destructive) {
                confirmingDelete = true
            }
        }
        .confirmationDialog("Delete this workout?", isPresented: $confirmingDelete, titleVisibility: .visible) {
            Button("Delete Workout", role: .destructive) {
                // Leave the screen first so it never renders a deleted workout.
                dismiss()
                log.delete(workout)
            }
        } message: {
            Text("This can't be undone.")
        }
    }

    /// One exercise as a tile: its name, then a row per set.
    ///
    /// - Parameter entry: The exercise entry to show.
    /// - Returns: The tile, tinted by the exercise's muscle group.
    private func entryTile(_ entry: ExerciseEntry) -> some View {
        let tint = entry.exercise?.muscle.tint ?? .accentColor
        return VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(entry.exercise?.name ?? "Exercise")
                .font(.tileTitle)
            ForEach(Array(entry.orderedSets.enumerated()), id: \.element.id) { index, set in
                HStack {
                    Text("\(index + 1)")
                        .font(.tileLabel)
                        .foregroundStyle(Color.textSecondary)
                        .frame(width: 24, alignment: .leading)
                    Text(unit.format(kilograms: set.weightKg))
                        .font(.scoreSmall)
                    Text("×")
                        .foregroundStyle(Color.textSecondary)
                    Text("\(set.reps)")
                        .font(.scoreSmall)
                }
            }
        }
        .tile(tint: tint)
    }
}
