import SwiftUI

/// A finished workout: its totals, then every exercise with its sets.
struct WorkoutDetailView: View {
    let workout: Workout

    @Environment(WorkoutLog.self) private var log
    @Environment(\.dismiss) private var dismiss
    @AppStorage("weightUnit") private var unit: WeightUnit = .kilograms
    @State private var confirmingDelete = false

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
                dismiss()
                log.delete(workout)
            }
        } message: {
            Text("This can't be undone.")
        }
    }

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
