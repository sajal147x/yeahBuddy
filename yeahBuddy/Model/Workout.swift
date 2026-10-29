import Foundation
import SwiftData

/// Every model the app persists. The app and tests build their containers from this list.
enum AppSchema {
    /// The full schema. Add new `@Model` types here or they will not be stored.
    static let schema = Schema([
        Workout.self, ExerciseEntry.self, SetEntry.self, Exercise.self,
    ])
}

/// One training session: when it started and ended, and the exercises done in it.
@Model
final class Workout {
    /// When the workout was started.
    var startedAt: Date
    /// Nil while the workout is in progress.
    var endedAt: Date?
    /// The exercises done, in no particular order. Read `orderedEntries` instead.
    /// Deleting the workout deletes these too.
    @Relationship(deleteRule: .cascade, inverse: \ExerciseEntry.workout)
    var entries: [ExerciseEntry] = []

    /// Creates an in-progress workout.
    ///
    /// - Parameter startedAt: When the workout began.
    init(startedAt: Date) {
        self.startedAt = startedAt
    }

    /// The exercises in the order they were added.
    /// SwiftData does not keep relationship order, so callers read entries through this.
    var orderedEntries: [ExerciseEntry] {
        entries.sorted { $0.position < $1.position }
    }

    /// Sum of weight × reps over every set, in kilograms.
    var totalVolumeKg: Double {
        entries.flatMap(\.sets).reduce(0) { $0 + $1.weightKg * Double($1.reps) }
    }

    /// How many sets were logged across all exercises.
    var setCount: Int {
        entries.reduce(0) { $0 + $1.sets.count }
    }
}

/// One exercise performed within a workout, with its sets.
@Model
final class ExerciseEntry {
    /// Where this exercise sits in the workout; lower comes first.
    var position: Int
    /// The exercise performed. Optional only because SwiftData requires it for relationships.
    var exercise: Exercise?
    /// The workout this belongs to.
    var workout: Workout?
    /// The logged sets, in no particular order. Read `orderedSets` instead.
    /// Deleting the entry deletes these too.
    @Relationship(deleteRule: .cascade, inverse: \SetEntry.entry)
    var sets: [SetEntry] = []

    /// Creates an entry for an exercise at a position in its workout.
    ///
    /// - Parameters:
    ///   - exercise: The exercise performed.
    ///   - position: Its place in the workout's order.
    init(exercise: Exercise, position: Int) {
        self.exercise = exercise
        self.position = position
    }

    /// Sets in the order they were completed.
    var orderedSets: [SetEntry] {
        sets.sorted { $0.completedAt < $1.completedAt }
    }
}

/// One completed set: a weight lifted for a number of reps.
@Model
final class SetEntry {
    /// Always kilograms; `WeightUnit` converts for display and input.
    var weightKg: Double
    /// How many repetitions were done.
    var reps: Int
    /// When the set was logged. Also used to order sets within an exercise.
    var completedAt: Date
    /// The exercise entry this set belongs to.
    var entry: ExerciseEntry?

    /// Creates a completed set.
    ///
    /// - Parameters:
    ///   - weightKg: The weight in kilograms.
    ///   - reps: The repetitions done.
    ///   - completedAt: When it was done.
    init(weightKg: Double, reps: Int, completedAt: Date) {
        self.weightKg = weightKg
        self.reps = reps
        self.completedAt = completedAt
    }
}
