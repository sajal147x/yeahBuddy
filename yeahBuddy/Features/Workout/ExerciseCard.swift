import SwiftUI

/// One exercise in the workout in progress: its logged sets, last session's remaining sets
/// faded below them as a plan to repeat, and an Add Set button that opens the pop-up for
/// logging the next one.
struct ExerciseCard: View {
    /// The exercise entry this card shows.
    let entry: ExerciseEntry
    /// The unit to show and enter weights in.
    let unit: WeightUnit
    /// Every set from the last finished workout with this exercise, in order; empty if none.
    let previousSets: [SetEntry]
    /// Called when the header is tapped, to fold this card back into a row.
    let onCollapse: () -> Void

    @Environment(WorkoutLog.self) private var log
    @Environment(RestTimer.self) private var restTimer
    @Environment(AddSetRequest.self) private var addSetRequest
    // The values for the next set, in `unit`, edited in the Add Set pop-up. Filled by
    // `prefill(from:)` each time the pop-up opens. Converted to kg only when logging.
    @State private var weight: Double
    @State private var reps: Double
    // Whether the Add Set pop-up is showing.
    @State private var addingSet = false

    /// How long the rest timer runs after each set, tapped or spoken. A common default for
    /// hypertrophy work.
    static let restSeconds: TimeInterval = 90

    /// Creates a card.
    ///
    /// - Parameters:
    ///   - entry: The exercise entry to show.
    ///   - unit: The unit for weights.
    ///   - previousSets: Last session's sets for this exercise, shown faded to repeat and used
    ///     to pre-fill each set's pop-up.
    ///   - onCollapse: Called when the header is tapped, to fold the card into a row.
    init(entry: ExerciseEntry, unit: WeightUnit, previousSets: [SetEntry], onCollapse: @escaping () -> Void) {
        self.entry = entry
        self.unit = unit
        self.previousSets = previousSets
        self.onCollapse = onCollapse
        // Placeholders only: `prefill(from:)` sets the real values when the pop-up opens.
        _weight = State(initialValue: unit.emptyBar)
        _reps = State(initialValue: 8)
    }

    /// Pill and controls, the centered name and set line, the done sets with last session's
    /// remaining sets faded under them, then Add Set, all on a card lit by the muscle color.
    var body: some View {
        VStack(spacing: Spacing.md) {
            header
            if !entry.sets.isEmpty || !pendingSets.isEmpty {
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
                    // Last session's sets beyond what's done today. Tapping one opens the
                    // pop-up filled with it, so repeating it is open + Add Set.
                    ForEach(Array(pendingSets.enumerated()), id: \.element.id) { offset, set in
                        Button {
                            openSheet(prefilledFrom: set)
                        } label: {
                            SetRow(
                                number: entry.sets.count + offset + 1,
                                weight: unit.formatNumber(kilograms: set.weightKg),
                                unit: unit.rawValue,
                                reps: set.reps,
                                isPending: true
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("Opens Add Set with last time's weight and reps")
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
                openSheet(prefilledFrom: nextSetToRepeat)
            }
            .buttonStyle(.inset)
        }
        .muscleGlowCard(entry.exercise?.muscle)
        // The Live Activity's Add Set button, once the workout screen has opened this card.
        .onChange(of: addSetRequest.isPending, initial: true) { _, isPending in
            if isPending && entry === log.currentEntry {
                addSetRequest.isPending = false
                openSheet(prefilledFrom: nextSetToRepeat)
            }
        }
        .sheet(isPresented: $addingSet) {
            AddSetSheet(
                exerciseName: entry.exercise?.name ?? "Exercise",
                setNumber: entry.sets.count + 1,
                unit: unit,
                lastTimeHint: lastTimeHint,
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

    /// The line under the name: the next set's number and what it was last time, e.g.
    /// "Set 2 · last time 135 lb × 8". Past last session's sets, today's last set instead.
    private var setLine: String {
        let next = "Set \(entry.sets.count + 1)"
        if let lastTime = lastTimeSet(at: entry.sets.count) {
            return "\(next) · last time \(unit.format(kilograms: lastTime.weightKg)) × \(lastTime.reps)"
        }
        if let last = entry.orderedSets.last {
            return "\(next) · last \(unit.format(kilograms: last.weightKg)) × \(last.reps)"
        }
        return next
    }

    /// Last session's sets that today hasn't reached yet: with 1 set done and 3 last time,
    /// sets 2 and 3.
    private var pendingSets: [SetEntry] {
        if entry.sets.count >= previousSets.count {
            return []
        }
        return Array(previousSets[entry.sets.count...])
    }

    /// The set the next one should start from: last time's matching set, otherwise today's
    /// last set, otherwise last time's final set. Nil for an exercise never done.
    private var nextSetToRepeat: SetEntry? {
        if let lastTime = lastTimeSet(at: entry.sets.count) {
            return lastTime
        }
        if let today = entry.orderedSets.last {
            return today
        }
        return previousSets.last
    }

    /// The pop-up's hint for the next set, e.g. "Last time: set 2 · 135 lb × 8".
    private var lastTimeHint: String? {
        guard let lastTime = lastTimeSet(at: entry.sets.count) else {
            return nil
        }
        return "Last time: set \(entry.sets.count + 1) · \(unit.format(kilograms: lastTime.weightKg)) × \(lastTime.reps)"
    }

    /// Last session's set at a position.
    ///
    /// - Parameter index: The 0-based set position.
    /// - Returns: That set, or nil if last session had fewer sets.
    private func lastTimeSet(at index: Int) -> SetEntry? {
        if index < previousSets.count {
            return previousSets[index]
        }
        return nil
    }

    /// Opens the Add Set pop-up with a set's weight and reps filled in.
    ///
    /// - Parameter set: The set to start from; nil starts at the empty bar for 8 reps.
    private func openSheet(prefilledFrom set: SetEntry?) {
        if let set {
            weight = unit.value(fromKilograms: set.weightKg)
            reps = Double(set.reps)
        } else {
            weight = unit.emptyBar
            reps = 8
        }
        addingSet = true
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
