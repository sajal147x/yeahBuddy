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

    /// Opens the log over a store and loads what is already saved: the workout in progress
    /// (if the app was closed mid-workout) and the history.
    ///
    /// - Parameters:
    ///   - container: The store to read and write. The log keeps it alive.
    ///   - now: The clock used for start, finish and set times. Defaults to the real time.
    init(container: ModelContainer, now: @escaping () -> Date = Date.init) {
        self.container = container
        self.now = now
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
    func logSet(weightKg: Double, reps: Int, of exercise: Exercise) {
        // `add` either finds this exercise's entry or creates it, so sets of the same
        // exercise always group together.
        let entry = add(exercise)
        entry.sets.append(SetEntry(weightKg: weightKg, reps: reps, completedAt: now()))
        save()
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
            return existing
        }
        // New exercises go to the end. Positions can have gaps after a removal, which is
        // fine because they are only ever used for sorting.
        let entry = ExerciseEntry(exercise: exercise, position: workout.entries.count)
        workout.entries.append(entry)
        save()
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
