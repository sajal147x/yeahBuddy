import AppIntents
import Foundation

/// What the Live Activity's buttons do, filled in by the app at launch.
///
/// The intents below are compiled into the widget extension too (its buttons need the types),
/// but they always *run* in the app's process. Routing through these closures keeps the
/// widget target free of app code like `RestTimer` and `WorkoutLog`. In the widget they stay
/// nil and are never called.
@MainActor
enum LiveActivityActions {
    /// Adds 15 seconds to the rest and updates the activity.
    static var extendRest: (() -> Void)?
    /// Ends the rest and updates the activity.
    static var skipRest: (() -> Void)?
    /// Brings up the Add Set pop-up for the current exercise.
    static var addSet: (() -> Void)?
}

/// The Live Activity's "+15s" button.
struct ExtendRestIntent: LiveActivityIntent {
    /// Shown by the system, e.g. in Shortcuts.
    static let title: LocalizedStringResource = "Add 15 Seconds of Rest"

    /// Runs in the app process; the app has wired up `extendRest` at launch.
    ///
    /// - Returns: Nothing to show; the activity updates itself.
    @MainActor
    func perform() async throws -> some IntentResult {
        LiveActivityActions.extendRest?()
        return .result()
    }
}

/// The Live Activity's "Skip" button.
struct SkipRestIntent: LiveActivityIntent {
    /// Shown by the system, e.g. in Shortcuts.
    static let title: LocalizedStringResource = "Skip Rest"

    /// Runs in the app process; the app has wired up `skipRest` at launch.
    ///
    /// - Returns: Nothing to show; the activity updates itself.
    @MainActor
    func perform() async throws -> some IntentResult {
        LiveActivityActions.skipRest?()
        return .result()
    }
}

/// The Live Activity's "Add Set" button: opens the app (unlocking if needed) on the pop-up.
/// Weight and reps can't be typed on the Lock Screen, so this hands over to the app.
struct OpenAddSetIntent: LiveActivityIntent {
    /// Shown by the system, e.g. in Shortcuts.
    static let title: LocalizedStringResource = "Add Set"
    /// Brings the app to the front before `perform` runs.
    static let openAppWhenRun = true

    /// Runs in the app process once it's in front; the app has wired up `addSet` at launch.
    ///
    /// - Returns: Nothing to show; the app presents the pop-up.
    @MainActor
    func perform() async throws -> some IntentResult {
        LiveActivityActions.addSet?()
        return .result()
    }
}
