/// The exercises every install comes with.
///
/// `ExerciseCatalog` adds any of these the store is missing on each launch (all of them the
/// first time, and new ones after an update), and fills in any description an older install
/// is missing. Names are the key that links a stored exercise back to this list, so renaming
/// one here won't update existing installs: it would show up as a second exercise instead.
///
/// Names follow a "Movement (Equipment)" pattern, e.g. "Bench Press (Dumbbell)", so the
/// versions of one movement sort together. The original 32 keep their older plain names.
/// Each muscle group's list lives in its own file to keep files short.
enum BuiltInExercises {
    /// One built-in: its name, main muscle group and a one-line "how to do it".
    typealias Entry = (name: String, muscle: MuscleGroup, summary: String)

    /// Every built-in exercise, grouped by muscle.
    static let all: [Entry] = chest + back + legs + shoulders + arms + core
}
