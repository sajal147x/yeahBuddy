/// Totals for one calendar week of training, shown on Home's This Week card.
struct WeekSummary: Equatable {
    /// How many workouts were finished.
    var workouts: Int
    /// How many sets those workouts logged in total.
    var sets: Int
    /// Sum of weight × reps across those sets, in kilograms.
    var volumeKg: Double
}
