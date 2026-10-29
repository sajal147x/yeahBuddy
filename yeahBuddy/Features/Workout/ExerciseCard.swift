import SwiftUI

/// One exercise in the workout in progress: its logged sets and the controls to log the next.
struct ExerciseCard: View {
    /// The exercise entry this card shows.
    let entry: ExerciseEntry
    /// The unit to show and enter weights in.
    let unit: WeightUnit

    @Environment(WorkoutLog.self) private var log
    @Environment(RestTimer.self) private var restTimer
    // The stepper values for the next set, in `unit`. Converted to kg only when logging.
    @State private var weight: Double
    @State private var reps: Double

    // How long the rest timer runs after each set. A common default for hypertrophy work.
    private static let restSeconds: TimeInterval = 90

    /// Creates a card, pre-filling the steppers so repeating the last set is one tap.
    ///
    /// - Parameters:
    ///   - entry: The exercise entry to show.
    ///   - unit: The unit for weights.
    init(entry: ExerciseEntry, unit: WeightUnit) {
        self.entry = entry
        self.unit = unit
        // Start from the last set so repeating it is one tap. A fresh exercise starts at
        // the empty bar in the user's unit (20 kg or 45 lb) for 8 reps.
        let last = entry.orderedSets.last
        _weight = State(initialValue: last.map { unit.value(fromKilograms: $0.weightKg) } ?? unit.emptyBar)
        _reps = State(initialValue: Double(last?.reps ?? 8))
    }

    /// Header, one row per logged set, the two steppers, then Log Set.
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            header
            if !entry.sets.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    ForEach(Array(entry.orderedSets.enumerated()), id: \.element.id) { index, set in
                        SetRow(
                            number: index + 1,
                            weight: unit.formatNumber(kilograms: set.weightKg),
                            unit: unit.rawValue,
                            reps: set.reps,
                            onDelete: { log.remove(set) }
                        )
                    }
                }
                Divider().overlay(Color.divider)
            }
            HStack {
                NumberStepper(value: $weight, step: unit.step, label: unit.rawValue)
                NumberStepper(value: $reps, step: 1, label: "Reps", format: { "\(Int($0))" })
            }
            Button("Log Set", action: logSet)
                .buttonStyle(.primary)
                // A set with zero reps isn't a set.
                .disabled(reps < 1)
        }
        .card()
    }

    /// The exercise name and muscle tag, with a menu to remove the exercise.
    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(entry.exercise?.name ?? "Exercise")
                    .font(.cardTitle)
                    .foregroundStyle(Color.textPrimary)
                if let muscle = entry.exercise?.muscle {
                    MuscleTag(muscle: muscle)
                }
            }
            Spacer()
            Menu {
                Button("Remove Exercise", systemImage: "trash", role: .destructive) {
                    log.remove(entry)
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.headline)
                    .foregroundStyle(Color.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(Color.surfaceRaised, in: Circle())
            }
            .accessibilityLabel("Exercise options")
        }
    }

    /// Logs the stepper values as a new set and starts the rest timer.
    private func logSet() {
        guard let exercise = entry.exercise else {
            return
        }
        // Steppers are in the user's unit; storage is always kilograms.
        log.logSet(weightKg: unit.kilograms(from: weight), reps: Int(reps), of: exercise)
        restTimer.start(seconds: Self.restSeconds)
    }
}
