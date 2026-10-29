import SwiftData
import SwiftUI

/// The app entry point: opens the store, creates the shared modules, and shows Home.
@main
struct yeahBuddyApp: App {
    // The app's three modules, created once and handed to every screen via the environment.
    @State private var log: WorkoutLog
    @State private var catalog: ExerciseCatalog
    @State private var restTimer = RestTimer()

    /// Opens the on-device store and builds the modules on top of it.
    init() {
        let container: ModelContainer
        do {
            container = try ModelContainer(for: AppSchema.schema)
        } catch {
            // Without a store the app can't do anything useful, so stop with a clear message.
            fatalError("Could not open the workout store: \(error)")
        }
        // Both modules keep the container alive, so it's fine that it's a local here.
        _log = State(initialValue: WorkoutLog(container: container))
        _catalog = State(initialValue: ExerciseCatalog(container: container))
    }

    /// One window showing Home, with the modules injected for every screen below it.
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(log)
                .environment(catalog)
                .environment(restTimer)
                // Scoreboard look: dark only for v1.
                .preferredColorScheme(.dark)
        }
    }
}
