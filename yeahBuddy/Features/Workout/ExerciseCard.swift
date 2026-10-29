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
        // 20 kg (an empty Olympic bar) for 8 reps.
        let last = entry.orderedSets.last
        _weight = State(initialValue: last.map { unit.value(fromKilograms: $0.weightKg) } ?? unit.value(fromKilograms: 20))
        _reps = State(initialValue: Double(last?.reps ?? 8))
    }

    /// The exercise's muscle color, used for the tile and the Log Set button.
    private var tint: Color {
        entry.exercise?.muscle.tint ?? .accentColor
    }

    /// Header, one row per logged set, the two steppers, then Log Set.
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            header
            ForEach(Array(entry.orderedSets.enumerated()), id: \.element.id) { index, set in
                setRow(number: index + 1, set: set)
            }
            HStack {
                NumberStepper(value: $weight, step: unit.step, label: unit.rawValue)
                NumberStepper(value: $reps, step: 1, label: "Reps", format: { "\(Int($0))" })
            }
            .padding(.top, Spacing.xs)
            Button("Log Set", action: logSet)
                .buttonStyle(.primary(tint: tint))
                // A set with zero reps isn't a set.
                .disabled(reps < 1)
        }
        .tile(tint: tint)
    }

    /// The exercise name and muscle group, with a menu to remove the exercise.
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.exercise?.name ?? "Exercise")
                    .font(.tileTitle)
                Text(entry.exercise?.muscle.displayName.uppercased() ?? "")
                    .font(.tileLabel)
                    .foregroundStyle(tint)
            }
            Spacer()
            Menu {
                Button("Remove Exercise", systemImage: "trash", role: .destructive) {
                    log.remove(entry)
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.headline)
                    .frame(width: 36, height: 36)
                    .background(Color.surfaceRaised, in: Circle())
            }
            .tint(Color.textPrimary)
        }
    }

    /// One logged set, e.g. "1   80 kg × 8", with a button to delete it.
    ///
    /// - Parameters:
    ///   - number: The set's 1-based position within this exercise.
    ///   - set: The logged set.
    /// - Returns: The row.
    private func setRow(number: Int, set: SetEntry) -> some View {
        HStack {
            Text("\(number)")
                .font(.tileLabel)
                .foregroundStyle(Color.textSecondary)
                .frame(width: 24, alignment: .leading)
            Text(unit.format(kilograms: set.weightKg))
                .font(.scoreSmall)
            Text("×")
                .foregroundStyle(Color.textSecondary)
            Text("\(set.reps)")
                .font(.scoreSmall)
            Spacer()
            // Icon only to keep the row compact; the title stays for VoiceOver.
            Button("Delete Set", systemImage: "xmark") {
                log.remove(set)
            }
            .labelStyle(.iconOnly)
            .font(.caption.weight(.bold))
            .foregroundStyle(Color.textSecondary)
            .buttonStyle(.plain)
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
