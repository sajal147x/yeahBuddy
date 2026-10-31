import ActivityKit
import Foundation

/// What the workout Live Activity shows. Compiled into both the app (which starts and updates
/// the activity) and the widget extension (which draws it), so it holds plain values only.
struct WorkoutActivityAttributes: ActivityAttributes {
    /// The parts that change during a workout. The app sends a new one after every change.
    struct ContentState: Codable, Hashable {
        /// The workout's title, e.g. "Chest · Legs".
        var title: String
        /// The exercise being worked on, e.g. "Bench Press"; nil before any is added.
        var exerciseName: String?
        /// The number of the next set of that exercise, e.g. 4 after three sets.
        var nextSetNumber: Int
        /// The exercise's latest set today, formatted in the user's unit, e.g. "135 lb × 8".
        var lastSet: String?
        /// When the rest ends; nil when not resting. The countdown runs to this by itself.
        var restEndsAt: Date?
        /// The full rest length including every +15s, for the "of 1:45" label and the bar.
        var restTotal: TimeInterval
    }

    /// When the workout started, for the clock. Fixed for the life of the activity.
    var startedAt: Date
}
