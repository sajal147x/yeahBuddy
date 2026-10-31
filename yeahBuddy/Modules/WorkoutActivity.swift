import ActivityKit
import Foundation

/// Keeps the workout's Live Activity (Lock Screen and Dynamic Island) in step with the app.
///
/// One method does everything: after anything changes, call `sync()`. It starts the activity
/// when a workout is in progress, updates it, and ends it once the workout is finished or
/// discarded. Callers never deal with ActivityKit, activity IDs or content states.
@MainActor
final class WorkoutActivity {
    // The workout being shown and the rest countdown, read on every sync.
    private let log: WorkoutLog
    private let rest: RestTimer
    // The activity on screen, if any. Picked up again after a relaunch.
    private var activity: Activity<WorkoutActivityAttributes>?

    // Same key Home's settings use through @AppStorage, read directly so a sync from a Lock
    // Screen button (with no view on screen) still uses the right unit.
    private static let unitKey = "weightUnit"

    /// Creates the module and reattaches to an activity left over from an earlier launch.
    ///
    /// - Parameters:
    ///   - log: The workout log to show.
    ///   - rest: The rest timer to show.
    init(log: WorkoutLog, rest: RestTimer) {
        self.log = log
        self.rest = rest
        activity = Activity<WorkoutActivityAttributes>.activities.first
    }

    /// Brings the Live Activity up to date: starts, updates or ends it to match the workout.
    ///
    /// Silent by design: updates never play a sound or vibrate, even when rest ends.
    func sync() {
        let unit = WeightUnit(rawValue: UserDefaults.standard.string(forKey: Self.unitKey) ?? "") ?? .kilograms
        guard let workout = log.active, let state = Self.content(log: log, rest: rest, unit: unit) else {
            endAll()
            return
        }
        // Stale once rest is over, which flips the activity to the "last set" layout even if
        // the app is asleep and can't send an update.
        let content = ActivityContent(state: state, staleDate: state.restEndsAt)

        if let activity, activity.attributes.startedAt == workout.startedAt, activity.activityState == .active {
            Task {
                await activity.update(content)
            }
            return
        }
        // No activity yet, or one left from an earlier workout: replace it.
        endAll()
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            // The user turned Live Activities off for the app; nothing to show.
            return
        }
        do {
            activity = try Activity.request(
                attributes: WorkoutActivityAttributes(startedAt: workout.startedAt),
                content: content
            )
        } catch {
            // Usually a system limit on Live Activities. The app works fine without one, so
            // carry on rather than bother the user.
            activity = nil
        }
    }

    /// What the activity should show right now.
    ///
    /// - Parameters:
    ///   - log: The workout log.
    ///   - rest: The rest timer.
    ///   - unit: The unit to show the last set in.
    /// - Returns: The content, or nil when no workout is in progress.
    static func content(log: WorkoutLog, rest: RestTimer, unit: WeightUnit) -> WorkoutActivityAttributes.ContentState? {
        guard let workout = log.active else {
            return nil
        }
        let current = log.currentEntry
        var lastSet: String?
        if let last = current?.orderedSets.last {
            lastSet = "\(unit.format(kilograms: last.weightKg)) × \(last.reps)"
        }
        return WorkoutActivityAttributes.ContentState(
            title: workout.title,
            exerciseName: current?.exercise?.name,
            nextSetNumber: (current?.sets.count ?? 0) + 1,
            lastSet: lastSet,
            restEndsAt: rest.endsAt,
            restTotal: rest.total
        )
    }

    /// Ends every workout activity straight away, including any from an earlier launch.
    private func endAll() {
        for running in Activity<WorkoutActivityAttributes>.activities {
            Task {
                await running.end(nil, dismissalPolicy: .immediate)
            }
        }
        activity = nil
    }
}
