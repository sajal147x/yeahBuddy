import SwiftUI

/// A finished workout: its date and totals, then every exercise with its sets.
struct WorkoutDetailView: View {
    /// The workout to show.
    let workout: Workout

    @Environment(WorkoutLog.self) private var log
    @Environment(\.dismiss) private var dismiss
    @AppStorage("weightUnit") private var unit: WeightUnit = .kilograms
    // Whether the "Delete this workout?" dialog is showing.
    @State private var confirmingDelete = false

    /// The summary card, one card per exercise, and a Delete button in the toolbar.
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text(workout.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                    HStack(alignment: .top) {
                        ForEach(workout.stats(in: unit)) { Stat($0) }
                    }
                }
                .card()
                ForEach(workout.orderedEntries) { entry in
                    entryCard(entry)
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

    /// One exercise on a card lit by its muscle's color, like the live workout: the muscle
    /// pill, its name, then a read-only row per set.
    ///
    /// - Parameter entry: The exercise entry to show.
    /// - Returns: The card.
    private func entryCard(_ entry: ExerciseEntry) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if let muscle = entry.exercise?.muscle {
                MusclePill(muscle: muscle)
            }
            Text(entry.exercise?.name ?? "Exercise")
                .font(.cardTitle)
                .foregroundStyle(Color.textPrimary)
            ForEach(Array(entry.orderedSets.enumerated()), id: \.element.id) { index, set in
                SetRow(
                    number: index + 1,
                    weight: unit.formatNumber(kilograms: set.weightKg),
                    unit: unit.rawValue,
                    reps: set.reps
                )
            }
            .padding(.top, Spacing.xs)
        }
        .muscleGlowCard(entry.exercise?.muscle)
    }
}
