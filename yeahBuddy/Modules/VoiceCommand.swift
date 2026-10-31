import Foundation

/// One thing the user asked for by voice, as understood by a `WorkoutParser`.
///
/// It's only a description: nothing is logged until `VoiceLogger` applies it, which keeps
/// the language model away from the data and makes every voice action undoable.
///
/// `nonisolated` because parsers build these off the main actor.
nonisolated enum VoiceCommand: Equatable, Sendable {
    /// "Add lat pulldown": put an exercise in the workout without logging a set.
    case addExercise(name: String)
    /// "Bench 100 for 8, twice": log `count` identical sets.
    ///
    /// A nil `exercise` means the one you're on. A nil `weight` means the same weight as
    /// that exercise's last set. A nil `unit` means the user's chosen unit.
    case logSets(exercise: String?, weight: Double?, unit: WeightUnit?, reps: Int, count: Int)
    /// "Same again" / "two more": log the last set again `count` times.
    case repeatLast(count: Int)
    /// "Make that 6 reps" / "it was 105": correct the last set. Nil fields stay as they were.
    case editLast(weight: Double?, unit: WeightUnit?, reps: Int?)
}
