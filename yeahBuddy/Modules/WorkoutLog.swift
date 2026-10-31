import Foundation
import Observation
import SwiftData

/// The single entry point for recording workouts. Views never touch SwiftData directly.
///
/// Everything a screen needs to do with workouts goes through this class: starting one,
/// adding exercises, logging and removing sets, finishing, and deleting. It keeps `active`
/// and `history` up to date itself, so views simply read them and SwiftUI redraws.
///
/// Invariant: at most one workout is in progress at a time.
@Observable
final class WorkoutLog {
    /// The workout in progress, if any.
    private(set) var active: Workout?
    /// Finished workouts, newest first.
    private(set) var history: [Workout] = []

    // Held so the store outlives every caller; a context alone does not keep it alive.
    // (Holding only a context crashed the app on the first insert.)
    private let container: ModelContainer
    // The main context, so changes are visible to SwiftUI immediately.
    private var context: ModelContext { container.mainContext }
    // Injected so tests can control time; the app uses the real clock.
    private let now: () -> Date
    // The exercise most recently added or logged to, behind `currentEntry`. In memory only:
    // which one you're on doesn't need to survive a relaunch.
    private var lastTouched: ExerciseEntry?
    // Decides where a week starts (Sunday or Monday depends on the user's region).
    // Injected so tests don't depend on the machine's locale.
    private let calendar: Calendar

    /// Opens the log over a store and loads what is already saved: the workout in progress
    /// (if the app was closed mid-workout) and the history.
    ///
    /// - Parameters:
    ///   - container: The store to read and write. The log keeps it alive.
    ///   - now: The clock used for start, finish and set times. Defaults to the real time.
    ///   - calendar: Used to find the start of the week. Defaults to the user's calendar.
    init(container: ModelContainer, now: @escaping () -> Date = Date.init, calendar: Calendar = .current) {
        self.container = container
        self.now = now
        self.calendar = calendar
        // One fetch, newest first, then split: an unfinished workout is the active one,
        // everything else is history (already in the right order).
        let newestFirst = FetchDescriptor<Workout>(sortBy: [SortDescriptor(\.startedAt, order: .reverse)])
        let workouts = (try? context.fetch(newestFirst)) ?? []
        active = workouts.first { $0.endedAt == nil }
        history = workouts.filter { $0.endedAt != nil }
    }

    /// Records a completed set. Starts a workout and adds the exercise to it when needed,
    /// so callers never have to prepare either.
    ///
    /// - Parameters:
    ///   - weightKg: The weight lifted, always in kilograms. Use `WeightUnit` to convert input.
    ///   - reps: How many repetitions were done.
    ///   - exercise: The exercise the set belongs to.
    /// - Returns: The new set, for callers that may need to undo it (voice logging).
    @discardableResult
    func logSet(weightKg: Double, reps: Int, of exercise: Exercise) -> SetEntry {
        // `add` either finds this exercise's entry or creates it, so sets of the same
        // exercise always group together.
        let entry = add(exercise)
        let set = SetEntry(weightKg: weightKg, reps: reps, completedAt: now())
        entry.sets.append(set)
        save()
        return set
    }

    /// Adds an exercise to the workout in progress, starting one if none is running.
    /// Adding an exercise that is already there returns its existing entry.
    ///
    /// - Parameter exercise: The exercise to add.
    /// - Returns: The entry for that exercise in the active workout.
    @discardableResult
    func add(_ exercise: Exercise) -> ExerciseEntry {
        let workout = start()
        if let existing = workout.entries.first(where: { $0.exercise == exercise }) {
            // `logSet` comes through here too, so this also marks the exercise being logged.
            lastTouched = existing
            return existing
        }
        // New exercises go to the end. Positions can have gaps after a removal, which is
        // fine because they are only ever used for sorting.
        let entry = ExerciseEntry(exercise: exercise, position: workout.entries.count)
        workout.entries.append(entry)
        save()
        lastTouched = entry
        return entry
    }

    /// Returns the workout in progress, starting a new one if none is running.
    ///
    /// - Returns: The active workout, which is never nil after this call.
    @discardableResult
    func start() -> Workout {
        if let active {
            return active
        }
        let workout = Workout(startedAt: now())
        context.insert(workout)
        active = workout
        return workout
    }

    /// Deletes a logged set, e.g. one entered by mistake.
    ///
    /// - Parameter set: The set to delete. Its exercise stays in the workout even if this
    ///   was its last set, so the user can log a corrected one.
    func remove(_ set: SetEntry) {
        // Detach first so the entry's `sets` updates right away; SwiftData would otherwise
        // only drop it from the relationship on the next save.
        set.entry?.sets.removeAll { $0 == set }
        context.delete(set)
        save()
    }

    /// Corrects a logged set, e.g. "make that 6 reps". Its time, and so its place in the
    /// exercise's order, stays the same.
    ///
    /// - Parameters:
    ///   - set: The set to change.
    ///   - weightKg: The corrected weight, always in kilograms.
    ///   - reps: The corrected repetitions.
    func update(_ set: SetEntry, weightKg: Double, reps: Int) {
        set.weightKg = weightKg
        set.reps = reps
        save()
    }

    /// Deletes an exercise and its sets from its workout, e.g. one added by mistake.
    ///
    /// - Parameter entry: The exercise entry to delete. Its sets are deleted with it.
    func remove(_ entry: ExerciseEntry) {
        // Same detach-then-delete as for sets, so the workout's list updates immediately.
        entry.workout?.entries.removeAll { $0 == entry }
        context.delete(entry)
        save()
    }

    /// Ends the workout in progress. A workout with no logged sets is discarded rather than
    /// kept as an empty record. Does nothing when none is running.
    func finish() {
        guard let workout = active else {
            return
        }
        let hasSets = workout.entries.contains { !$0.sets.isEmpty }
        if hasSets {
            workout.endedAt = now()
            active = nil
            // It just finished, so it is the newest item in history.
            history.insert(workout, at: 0)
            save()
        } else {
            delete(workout)
        }
    }

    /// Permanently deletes a workout, whether it is in progress or finished.
    ///
    /// - Parameter workout: The workout to delete, along with all its exercises and sets.
    func delete(_ workout: Workout) {
        if active == workout {
            active = nil
        }
        history.removeAll { $0 == workout }
        context.delete(workout)
        save()
    }

    /// Totals for finished workouts that started in the current calendar week.
    ///
    /// The workout in progress is left out until it's finished, so the numbers don't jump
    /// around mid-session.
    ///
    /// - Returns: Workout, set and volume totals for this week; all zero if nothing yet.
    func thisWeek() -> WeekSummary {
        guard let week = calendar.dateInterval(of: .weekOfYear, for: now()) else {
            return WeekSummary(workouts: 0, sets: 0, volumeKg: 0)
        }
        // History is already finished-only, so filtering by start date is enough.
        let workouts = history.filter { week.contains($0.startedAt) }
        return WeekSummary(
            workouts: workouts.count,
            sets: workouts.reduce(0) { $0 + $1.setCount },
            volumeKg: workouts.reduce(0) { $0 + $1.totalVolumeKg }
        )
    }

    /// The exercise you're working on in the workout in progress, for places outside the
    /// workout screen (the Live Activity) that need to name it.
    ///
    /// The workout screen tracks which card is open as UI state; this is the logic version.
    ///
    /// It's the exercise last added or logged to. After a relaunch (which forgets that), it's
    /// the exercise with the most recent set, or the newest one if nothing is logged yet.
    var currentEntry: ExerciseEntry? {
        guard let workout = active else {
            return nil
        }
        if let lastTouched, workout.entries.contains(where: { $0 === lastTouched }) {
            return lastTouched
        }
        let withSets = workout.entries.filter { !$0.sets.isEmpty }
        if let latest = withSets.max(by: { latestSetTime(of: $0) < latestSetTime(of: $1) }) {
            return latest
        }
        return workout.orderedEntries.last
    }

    /// When an entry's most recent set was done.
    ///
    /// - Parameter entry: An entry with at least one set.
    /// - Returns: The latest completion time, or the distant past if it has no sets.
    private func latestSetTime(of entry: ExerciseEntry) -> Date {
        entry.orderedSets.last?.completedAt ?? .distantPast
    }

    /// The set you finished on the last time you did an exercise, so a new card can start
    /// from that weight and reps instead of the empty bar.
    ///
    /// Only finished workouts count: the one in progress already shows its own sets, and
    /// pre-filling from it would just echo them back. A workout where the exercise was added
    /// but no sets were logged is skipped, so it doesn't hide the session before it.
    ///
    /// - Parameter exercise: The exercise to look up.
    /// - Returns: The final set from the newest finished workout with sets of `exercise`,
    ///   or nil if it has never been done.
    func lastSet(of exercise: Exercise) -> SetEntry? {
        // History is newest first, so the first workout with a matching set wins.
        for workout in history {
            let entry = workout.entries.first { $0.exercise == exercise }
            if let last = entry?.orderedSets.last {
                return last
            }
        }
        return nil
    }

    /// Writes immediately rather than waiting for autosave, so a set logged just before the
    /// app is killed mid-workout is not lost.
    private func save() {
        do {
            try context.save()
        } catch {
            // A failed save means the disk is full or the store is corrupt; there is nothing
            // useful a caller could do, so flag it loudly in debug builds only.
            assertionFailure("Saving workouts failed: \(error)")
        }
    }
}
