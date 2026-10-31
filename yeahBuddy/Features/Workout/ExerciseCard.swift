import SwiftUI

/// One exercise in the workout in progress: its logged sets and an Add Set button that opens
/// the pop-up for logging the next one.
struct ExerciseCard: View {
    /// The exercise entry this card shows.
    let entry: ExerciseEntry
    /// The unit to show and enter weights in.
    let unit: WeightUnit
    /// The final set from the last finished workout with this exercise, if there is one.
    let previous: SetEntry?
    /// Called when the header is tapped, to fold this card back into a row.
    let onCollapse: () -> Void

    @Environment(WorkoutLog.self) private var log
    @Environment(RestTimer.self) private var restTimer
    @Environment(AddSetRequest.self) private var addSetRequest
    // The values for the next set, in `unit`, edited in the Add Set pop-up. Kept here so they
    // survive between pop-ups. Converted to kg only when logging.
    @State private var weight: Double
    @State private var reps: Double
    // Whether the Add Set pop-up is showing.
    @State private var addingSet = false

    /// How long the rest timer runs after each set, tapped or spoken. A common default for
    /// hypertrophy work.
    static let restSeconds: TimeInterval = 90

    /// Creates a card, pre-filling the next set so repeating the last one needs no changes.
    ///
    /// - Parameters:
    ///   - entry: The exercise entry to show.
    ///   - unit: The unit for weights.
    ///   - previous: The final set from the last time this exercise was done, used to
    ///     pre-fill the steppers before anything is logged today.
    ///   - onCollapse: Called when the header is tapped, to fold the card into a row.
    init(entry: ExerciseEntry, unit: WeightUnit, previous: SetEntry?, onCollapse: @escaping () -> Void) {
        self.entry = entry
        self.unit = unit
        self.previous = previous
        self.onCollapse = onCollapse
        // Start from today's last set so repeating it is one tap. Before any set today,
        // start from where the last session ended. An exercise never done before starts
        // at the empty bar in the user's unit (20 kg or 45 lb) for 8 reps.
        let last = entry.orderedSets.last ?? previous
        _weight = State(initialValue: last.map { unit.value(fromKilograms: $0.weightKg) } ?? unit.emptyBar)
        _reps = State(initialValue: Double(last?.reps ?? 8))
    }

    /// Pill and controls, the centered name and set line, the done sets, then Add Set, all
    /// on a card lit by the exercise's muscle color.
    var body: some View {
        VStack(spacing: Spacing.md) {
            header
            if !entry.sets.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    ForEach(Array(entry.orderedSets.enumerated()), id: \.element.id) { index, set in
                        SetRow(
                            number: index + 1,
                            weight: unit.formatNumber(kilograms: set.weightKg),
                            unit: unit.rawValue,
                            reps: set.reps,
                            onDelete: { log.remove(set) },
                            showsCheck: true,
                            checkColor: entry.exercise?.muscle.tint ?? .brand
                        )
                    }
                }
                // A see-through panel so the done sets stand apart while the card's color
                // still shows through.
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.inset, in: RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
            }
            // Opens the pop-up rather than logging straight away, so a stray tap here is
            // harmless: logging always takes the pop-up's own Add Set as well.
            Button("Add Set", systemImage: "plus") {
                addingSet = true
            }
            .buttonStyle(.inset)
        }
        .muscleGlowCard(entry.exercise?.muscle)
        // The Live Activity's Add Set button, once the workout screen has opened this card.
        .onChange(of: addSetRequest.isPending, initial: true) { _, isPending in
            if isPending && entry === log.currentEntry {
                addSetRequest.isPending = false
                addingSet = true
            }
        }
        .sheet(isPresented: $addingSet) {
            AddSetSheet(
                exerciseName: entry.exercise?.name ?? "Exercise",
                setNumber: entry.sets.count + 1,
                unit: unit,
                previous: previous,
                weight: $weight,
                reps: $reps,
                onAdd: logSet
            )
        }
    }

    /// The muscle pill, collapse chevron and options menu in a row, then the exercise name
    /// centered with the set line under it. Tapping anywhere but the menu collapses the card.
    private var header: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: onCollapse) {
                VStack(spacing: Spacing.sm) {
                    HStack {
                        if let muscle = entry.exercise?.muscle {
                            MusclePill(muscle: muscle)
                        }
                        Spacer()
                        Image(systemName: "chevron.up")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Color.textSecondary)
                            // Clear of the options menu, which sits over this corner.
                            .padding(.trailing, 44)
                    }
                    .frame(height: 36)
                    VStack(spacing: Spacing.xs) {
                        Text(entry.exercise?.name ?? "Exercise")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Color.textPrimary)
                            .multilineTextAlignment(.center)
                        Text(setLine)
                            .font(.label)
                            .foregroundStyle(Color.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                // The empty space around the name is tappable too.
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Double tap to collapse")
            Menu {
                Button("Remove Exercise", systemImage: "trash", role: .destructive) {
                    log.remove(entry)
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.headline)
                    .foregroundStyle(Color.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(Color.inset, in: Circle())
            }
            .accessibilityLabel("Exercise options")
        }
    }

    /// The line under the name: the next set's number and the set to beat, e.g.
    /// "Set 3 · last 135 lb × 8". Before any set today it shows last session's final set.
    private var setLine: String {
        let next = "Set \(entry.sets.count + 1)"
        if let last = entry.orderedSets.last {
            return "\(next) · last \(unit.format(kilograms: last.weightKg)) × \(last.reps)"
        }
        if let previous {
            return "\(next) · last time \(unit.format(kilograms: previous.weightKg)) × \(previous.reps)"
        }
        return next
    }

    /// Logs the pop-up's values as a new set and starts the rest timer.
    private func logSet() {
        guard let exercise = entry.exercise else {
            return
        }
        // Steppers are in the user's unit; storage is always kilograms.
        log.logSet(weightKg: unit.kilograms(from: weight), reps: Int(reps), of: exercise)
        restTimer.start(seconds: Self.restSeconds)
    }
}
