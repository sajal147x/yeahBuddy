import SwiftData
import SwiftUI

@main
struct yeahBuddyApp: App {
    @State private var log: WorkoutLog
    @State private var catalog: ExerciseCatalog
    @State private var restTimer = RestTimer()

    init() {
        let container: ModelContainer
        do {
            container = try ModelContainer(for: AppSchema.schema)
        } catch {
            fatalError("Could not open the workout store: \(error)")
        }
        _log = State(initialValue: WorkoutLog(container: container))
        _catalog = State(initialValue: ExerciseCatalog(container: container))
    }

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
