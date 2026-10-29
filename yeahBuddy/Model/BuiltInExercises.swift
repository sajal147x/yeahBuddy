/// The exercises every install starts with.
///
/// `ExerciseCatalog` copies these into the store on first launch only, so editing this list
/// later does not change existing installs.
enum BuiltInExercises {
    /// Name and muscle group for each built-in exercise, grouped by muscle for readability.
    static let all: [(name: String, muscle: MuscleGroup)] = [
        ("Bench Press", .chest),
        ("Incline Dumbbell Press", .chest),
        ("Chest Fly", .chest),
        ("Push-up", .chest),
        ("Dip", .chest),
        ("Deadlift", .back),
        ("Pull-up", .back),
        ("Lat Pulldown", .back),
        ("Barbell Row", .back),
        ("Seated Cable Row", .back),
        ("Squat", .legs),
        ("Front Squat", .legs),
        ("Romanian Deadlift", .legs),
        ("Leg Press", .legs),
        ("Lunge", .legs),
        ("Leg Curl", .legs),
        ("Leg Extension", .legs),
        ("Calf Raise", .legs),
        ("Hip Thrust", .legs),
        ("Overhead Press", .shoulders),
        ("Dumbbell Shoulder Press", .shoulders),
        ("Lateral Raise", .shoulders),
        ("Face Pull", .shoulders),
        ("Rear Delt Fly", .shoulders),
        ("Barbell Curl", .arms),
        ("Dumbbell Curl", .arms),
        ("Hammer Curl", .arms),
        ("Tricep Pushdown", .arms),
        ("Skull Crusher", .arms),
        ("Plank", .core),
        ("Hanging Leg Raise", .core),
        ("Cable Crunch", .core),
    ]
}
