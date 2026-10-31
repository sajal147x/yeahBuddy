import SwiftData
import SwiftUI

/// The app entry point: opens the store, creates the shared modules, and shows the tabs.
@main
struct yeahBuddyApp: App {
    // The app's modules, created once and handed to every screen via the environment.
    @State private var log: WorkoutLog
    @State private var catalog: ExerciseCatalog
    @State private var restTimer: RestTimer
    // Not a view dependency, so plain storage: it's handed to RootView, which syncs it.
    private let activity: WorkoutActivity
    // Set by the Live Activity's Add Set button; screens react to it.
    @State private var addSetRequest = AddSetRequest()

    /// Opens the on-device store, builds the modules on top of it, and wires up the Live
    /// Activity's buttons.
    init() {
        let container: ModelContainer
        do {
            container = try ModelContainer(for: AppSchema.schema)
        } catch {
            // Without a store the app can't do anything useful, so stop with a clear message.
            fatalError("Could not open the workout store: \(error)")
        }
        // Both modules keep the container alive, so it's fine that it's a local here.
        let log = WorkoutLog(container: container)
        let restTimer = RestTimer()
        let activity = WorkoutActivity(log: log, rest: restTimer)
        let addSetRequest = AddSetRequest()
        _log = State(initialValue: log)
        _catalog = State(initialValue: ExerciseCatalog(container: container))
        _restTimer = State(initialValue: restTimer)
        _addSetRequest = State(initialValue: addSetRequest)
        self.activity = activity

        // The Lock Screen buttons run in this process, possibly with no screen visible, so
        // each one syncs the activity itself rather than waiting for a view to notice.
        LiveActivityActions.extendRest = {
            restTimer.extend(by: 15)
            activity.sync()
        }
        LiveActivityActions.skipRest = {
            restTimer.skip()
            activity.sync()
        }
        LiveActivityActions.addSet = {
            addSetRequest.isPending = true
        }
    }

    /// One window showing the tabs, with the modules injected for every screen below it.
    var body: some Scene {
        WindowGroup {
            RootView(activity: activity)
                .environment(log)
                .environment(catalog)
                .environment(restTimer)
                .environment(addSetRequest)
        }
    }
}
