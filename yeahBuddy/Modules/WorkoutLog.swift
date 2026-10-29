import Foundation
import Observation
import SwiftData

/// The single entry point for recording workouts. Views never touch SwiftData directly.
@Observable
final class WorkoutLog {
    /// The workout in progress, if any.
    private(set) var active: Workout?
    /// Finished workouts, newest first.
    private(set) var history: [Workout] = []

    // Held so the store outlives every caller; a context alone does not keep it alive.
    private let container: ModelContainer
    private var context: ModelContext { container.mainContext }
    private let now: () -> Date

    init(container: ModelContainer, now: @escaping () -> Date = Date.init) {
        self.container = container
        self.now = now
        let newestFirst = FetchDescriptor<Workout>(sortBy: [SortDescriptor(\.startedAt, order: .reverse)])
        let workouts = (try? context.fetch(newestFirst)) ?? []
        active = workouts.first { $0.endedAt == nil }
        history = workouts.filter { $0.endedAt != nil }
    }

    /// Records a completed set. Starts a workout and adds the exercise to it when needed,
    /// so callers never have to prepare either.
    func logSet(weightKg: Double, reps: Int, of exercise: Exercise) {
        let entry = add(exercise)
        entry.sets.append(SetEntry(weightKg: weightKg, reps: reps, completedAt: now()))
        save()
    }

    /// Adds an exercise to the workout in progress, starting one if none is running.
    /// Adding an exercise that is already there returns its existing entry.
    @discardableResult
    func add(_ exercise: Exercise) -> ExerciseEntry {
        let workout = start()
        if let existing = workout.entries.first(where: { $0.exercise == exercise }) {
            return existing
        }
        let entry = ExerciseEntry(exercise: exercise, position: workout.entries.count)
        workout.entries.append(entry)
        save()
        return entry
    }

    /// Returns the workout in progress, starting a new one if none is running.
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
    func remove(_ set: SetEntry) {
        set.entry?.sets.removeAll { $0 == set }
        context.delete(set)
        save()
    }

    /// Deletes an exercise and its sets from its workout, e.g. one added by mistake.
    func remove(_ entry: ExerciseEntry) {
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
            history.insert(workout, at: 0)
            save()
        } else {
            delete(workout)
        }
    }

    /// Permanently deletes a workout, whether it is in progress or finished.
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
            assertionFailure("Saving workouts failed: \(error)")
        }
    }
}
