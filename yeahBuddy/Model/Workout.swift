import Foundation
import SwiftData

/// Every model the app persists. The app and tests build their containers from this list.
enum AppSchema {
    static let schema = Schema([
        Workout.self, ExerciseEntry.self, SetEntry.self, Exercise.self,
    ])
}

@Model
final class Workout {
    var startedAt: Date
    /// Nil while the workout is in progress.
    var endedAt: Date?
    @Relationship(deleteRule: .cascade, inverse: \ExerciseEntry.workout)
    var entries: [ExerciseEntry] = []

    init(startedAt: Date) {
        self.startedAt = startedAt
    }

    /// SwiftData does not keep relationship order, so callers read entries through this.
    var orderedEntries: [ExerciseEntry] {
        entries.sorted { $0.position < $1.position }
    }

    /// Sum of weight × reps over every set.
    var totalVolumeKg: Double {
        entries.flatMap(\.sets).reduce(0) { $0 + $1.weightKg * Double($1.reps) }
    }

    var setCount: Int {
        entries.reduce(0) { $0 + $1.sets.count }
    }
}

/// One exercise performed within a workout, with its sets.
@Model
final class ExerciseEntry {
    var position: Int
    var exercise: Exercise?
    var workout: Workout?
    @Relationship(deleteRule: .cascade, inverse: \SetEntry.entry)
    var sets: [SetEntry] = []

    init(exercise: Exercise, position: Int) {
        self.exercise = exercise
        self.position = position
    }

    /// Sets in the order they were completed.
    var orderedSets: [SetEntry] {
        sets.sorted { $0.completedAt < $1.completedAt }
    }
}

@Model
final class SetEntry {
    /// Always kilograms; `WeightUnit` converts for display and input.
    var weightKg: Double
    var reps: Int
    var completedAt: Date
    var entry: ExerciseEntry?

    init(weightKg: Double, reps: Int, completedAt: Date) {
        self.weightKg = weightKg
        self.reps = reps
        self.completedAt = completedAt
    }
}
