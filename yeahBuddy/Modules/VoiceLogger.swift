import Foundation

/// Applies what the user said (already parsed into `VoiceCommand`s) to the workout, and can
/// take it back.
///
/// This is where every decision about voice input is made: which exercise a spoken name
/// means, what "same again" repeats, which weight a bare "for 6" uses. The language model
/// only describes; this module acts, through `WorkoutLog` and `ExerciseCatalog` like any view.
///
/// A batch of commands is all or nothing: if one can't be done, the ones before it are
/// rolled back, so a half-understood sentence never leaves half its sets behind.
final class VoiceLogger {
    private let log: WorkoutLog
    private let catalog: ExerciseCatalog

    /// Creates a voice logger over the app's log and catalog.
    ///
    /// - Parameters:
    ///   - log: Where sets are logged.
    ///   - catalog: Where spoken exercise names are looked up.
    init(log: WorkoutLog, catalog: ExerciseCatalog) {
        self.log = log
        self.catalog = catalog
    }

    /// Carries out the commands, in order.
    ///
    /// - Parameters:
    ///   - commands: What was said, as parsed.
    ///   - unit: The user's weight unit, for weights said without one and for the summary.
    /// - Returns: A summary to show plus the change (for Undo), or why nothing was done.
    func apply(_ commands: [VoiceCommand], unit: WeightUnit) -> VoiceOutcome {
        if commands.isEmpty {
            return .failed("Didn't catch that")
        }
        var run = Run(unit: unit, latest: latestSet())
        for command in commands {
            if let problem = perform(command, in: &run) {
                // All or nothing: take back whatever the earlier commands did.
                undo(run.change)
                return .failed(problem)
            }
        }
        return .applied(summary: run.summary.joined(separator: " · "), change: run.change)
    }

    /// Takes back everything one `apply` did: edited sets get their old values back, then
    /// new sets and newly added exercises are removed.
    ///
    /// - Parameter change: The change from an `.applied` outcome.
    func undo(_ change: VoiceChange) {
        for edit in change.edits.reversed() {
            log.update(edit.set, weightKg: edit.oldWeightKg, reps: edit.oldReps)
        }
        // Sets before entries: removing an entry already deletes its sets.
        for set in change.addedSets {
            log.remove(set)
        }
        for entry in change.addedEntries {
            log.remove(entry)
        }
    }

    // MARK: - One command

    /// State carried across the commands of one `apply`.
    private struct Run {
        /// The user's unit.
        let unit: WeightUnit
        /// The set "same again" and "make that" refer to; moves as sets are logged.
        var latest: SetEntry?
        /// Everything done so far, for undo or rollback.
        var change = VoiceChange()
        /// One phrase per command, e.g. "Added Lat Pulldown".
        var summary: [String] = []
    }

    /// Carries out one command, recording what it did in `run`.
    ///
    /// - Parameters:
    ///   - command: The command.
    ///   - run: The batch's state, updated in place.
    /// - Returns: Nil on success, or a short message saying why it couldn't be done.
    private func perform(_ command: VoiceCommand, in run: inout Run) -> String? {
        switch command {
        case .addExercise(let name):
            guard let exercise = find(name) else {
                return "Couldn't find “\(name)”"
            }
            addToWorkout(exercise, in: &run)
            run.summary.append("Added \(exercise.name)")
            return nil

        case .logSets(let name, let weight, let spokenUnit, let reps, let count):
            let exercise: Exercise
            if let name {
                guard let found = find(name) else {
                    return "Couldn't find “\(name)”"
                }
                exercise = found
            } else {
                guard let current = log.currentEntry?.exercise else {
                    return "Say which exercise"
                }
                exercise = current
            }
            let weightKg: Double
            if let weight {
                weightKg = (spokenUnit ?? run.unit).kilograms(from: weight)
            } else {
                guard let previous = previousWeightKg(of: exercise) else {
                    return "Say the weight"
                }
                weightKg = previous
            }
            log(count, sets: weightKg, reps: reps, of: exercise, in: &run)
            return nil

        case .repeatLast(let count):
            guard let latest = run.latest, let exercise = latest.entry?.exercise else {
                return "No set to repeat yet"
            }
            log(count, sets: latest.weightKg, reps: latest.reps, of: exercise, in: &run)
            return nil

        case .editLast(let weight, let spokenUnit, let reps):
            guard let latest = run.latest, let exercise = latest.entry?.exercise else {
                return "No set to change yet"
            }
            run.change.edits.append(VoiceChange.Edit(set: latest, oldWeightKg: latest.weightKg, oldReps: latest.reps))
            var newWeightKg = latest.weightKg
            if let weight {
                newWeightKg = (spokenUnit ?? run.unit).kilograms(from: weight)
            }
            log.update(latest, weightKg: newWeightKg, reps: reps ?? latest.reps)
            run.summary.append("Changed to \(describe(exercise, latest.weightKg, latest.reps, unit: run.unit))")
            return nil
        }
    }

    /// Logs `count` identical sets (at least one) and records them.
    ///
    /// - Parameters:
    ///   - count: How many sets; below 1 counts as 1.
    ///   - weightKg: The weight in kilograms.
    ///   - reps: The reps per set.
    ///   - exercise: The exercise.
    ///   - run: The batch's state, updated in place.
    private func log(_ count: Int, sets weightKg: Double, reps: Int, of exercise: Exercise, in run: inout Run) {
        addToWorkout(exercise, in: &run)
        let times = max(count, 1)
        for _ in 0..<times {
            let set = log.logSet(weightKg: weightKg, reps: reps, of: exercise)
            run.change.addedSets.append(set)
            run.latest = set
        }
        let described = describe(exercise, weightKg, reps, unit: run.unit)
        if times > 1 {
            run.summary.append("Logged \(times) × \(described)")
        } else {
            run.summary.append("Logged \(described)")
        }
    }

    /// Adds the exercise to the workout, remembering it for undo only if it wasn't there yet.
    ///
    /// - Parameters:
    ///   - exercise: The exercise.
    ///   - run: The batch's state, updated in place.
    private func addToWorkout(_ exercise: Exercise, in run: inout Run) {
        let alreadyThere = log.active?.entries.contains { $0.exercise == exercise } ?? false
        let entry = log.add(exercise)
        if !alreadyThere {
            run.change.addedEntries.append(entry)
        }
    }

    // MARK: - Lookups

    /// The exercise a spoken name means: an exact match ignoring case, otherwise the
    /// shortest name containing it. Shortest is the plainest variant, so "bench" is Bench
    /// Press rather than Incline Bench Press (Barbell); people name the variant when they mean it.
    ///
    /// - Parameter name: The name as parsed.
    /// - Returns: The exercise, or nil when no name contains it.
    private func find(_ name: String) -> Exercise? {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let exact = catalog.all.first(where: { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            return exact
        }
        return catalog.search(trimmed).min { $0.name.count < $1.name.count }
    }

    /// The weight to use when none was said: this exercise's last set in this workout,
    /// otherwise its last set ever.
    ///
    /// - Parameter exercise: The exercise.
    /// - Returns: The weight in kilograms, or nil if it has never been done.
    private func previousWeightKg(of exercise: Exercise) -> Double? {
        let entry = log.active?.entries.first { $0.exercise == exercise }
        if let last = entry?.orderedSets.last {
            return last.weightKg
        }
        return log.lastSet(of: exercise)?.weightKg
    }

    /// The most recently completed set in the workout in progress.
    ///
    /// - Returns: That set, or nil when nothing is logged yet.
    private func latestSet() -> SetEntry? {
        let sets = log.active?.entries.flatMap(\.sets) ?? []
        return sets.max { $0.completedAt < $1.completedAt }
    }

    /// A set in words, e.g. "Bench Press 100 kg × 8".
    ///
    /// - Parameters:
    ///   - exercise: The exercise.
    ///   - weightKg: The weight in kilograms.
    ///   - reps: The reps.
    ///   - unit: The unit to show the weight in.
    /// - Returns: The description.
    private func describe(_ exercise: Exercise, _ weightKg: Double, _ reps: Int, unit: WeightUnit) -> String {
        "\(exercise.name) \(unit.format(kilograms: weightKg)) × \(reps)"
    }
}

/// What `VoiceLogger.apply` produced.
enum VoiceOutcome: Equatable {
    /// Done. `summary` is for the banner; `change` is for Undo.
    case applied(summary: String, change: VoiceChange)
    /// Nothing was changed, with a short reason to show the user.
    case failed(String)
}

/// Everything one voice action changed, so `VoiceLogger.undo` can take it back exactly.
struct VoiceChange: Equatable {
    /// A set that was corrected, with what it was before.
    struct Edit: Equatable {
        /// The corrected set.
        let set: SetEntry
        /// Its weight before the correction, in kilograms.
        let oldWeightKg: Double
        /// Its reps before the correction.
        let oldReps: Int
    }

    /// Sets that were logged.
    var addedSets: [SetEntry] = []
    /// Exercises that weren't in the workout before.
    var addedEntries: [ExerciseEntry] = []
    /// Sets that were corrected.
    var edits: [Edit] = []
}
