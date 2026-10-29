import SwiftUI

/// One exercise in the workout in progress: its logged sets and the controls to log the next.
struct ExerciseCard: View {
    let entry: ExerciseEntry
    let unit: WeightUnit

    @Environment(WorkoutLog.self) private var log
    @Environment(RestTimer.self) private var restTimer
    @State private var weight: Double
    @State private var reps: Double

    private static let restSeconds: TimeInterval = 90

    init(entry: ExerciseEntry, unit: WeightUnit) {
        self.entry = entry
        self.unit = unit
        // Start from the last set so repeating it is one tap.
        let last = entry.orderedSets.last
        _weight = State(initialValue: last.map { unit.value(fromKilograms: $0.weightKg) } ?? unit.value(fromKilograms: 20))
        _reps = State(initialValue: Double(last?.reps ?? 8))
    }

    private var tint: Color {
        entry.exercise?.muscle.tint ?? .accentColor
    }

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
                .disabled(reps < 1)
        }
        .tile(tint: tint)
    }

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
            Button("Delete Set", systemImage: "xmark") {
                log.remove(set)
            }
            .labelStyle(.iconOnly)
            .font(.caption.weight(.bold))
            .foregroundStyle(Color.textSecondary)
            .buttonStyle(.plain)
        }
    }

    private func logSet() {
        guard let exercise = entry.exercise else {
            return
        }
        log.logSet(weightKg: unit.kilograms(from: weight), reps: Int(reps), of: exercise)
        restTimer.start(seconds: Self.restSeconds)
    }
}
