import SwiftUI

/// The app's three tabs, in the order they appear in the tab bar.
enum AppTab: String, Hashable {
    case home, history, exercises

    /// The label under the tab's icon.
    var title: String {
        switch self {
        case .home: return "Home"
        case .history: return "History"
        case .exercises: return "Exercises"
        }
    }

    /// The tab's SF Symbol.
    var systemImage: String {
        switch self {
        case .home: return "house"
        case .history: return "clock.arrow.circlepath"
        case .exercises: return "dumbbell"
        }
    }
}

/// The top-level screen: the system tab bar with Home, History and Exercises.
///
/// The system bar is used rather than a custom one so it gets iOS 26's Liquid Glass, the
/// sliding selection bubble and shrink-on-scroll for free. Screens scroll underneath it,
/// which is what lets the glass show through.
struct RootView: View {
    /// The Live Activity, kept in step with the workout from here.
    let activity: WorkoutActivity

    @Environment(WorkoutLog.self) private var log
    @Environment(RestTimer.self) private var restTimer
    @Environment(AddSetRequest.self) private var addSetRequest
    // Shared with Home's settings menu and restored on the next launch.
    @AppStorage("appearance") private var appearance: AppAppearance = .system
    // Read here only so changing the unit refreshes the Live Activity's last set.
    @AppStorage("weightUnit") private var unit: WeightUnit = .kilograms
    // Which tab is showing. Starts on Home every launch.
    @State private var tab: AppTab = .home

    /// The three tabs. Each keeps its own navigation stack and scroll position when you switch.
    var body: some View {
        TabView(selection: $tab) {
            Tab(AppTab.home.title, systemImage: AppTab.home.systemImage, value: AppTab.home) {
                HomeView()
            }
            Tab(AppTab.history.title, systemImage: AppTab.history.systemImage, value: AppTab.history) {
                HistoryView()
            }
            Tab(AppTab.exercises.title, systemImage: AppTab.exercises.systemImage, value: AppTab.exercises) {
                ExercisesView()
            }
        }
        // The selected tab's icon and label in the brand teal (mint in dark mode).
        .tint(Color.brand)
        // Scrolling down a long list shrinks the bar out of the way; scrolling up brings it back.
        .tabBarMinimizeBehavior(.onScrollDown)
        .preferredColorScheme(appearance.colorScheme)
        // One place keeps the Live Activity current: whenever what it would show changes
        // (a set, an exercise, rest, finishing), sync it. `initial` also ends an activity
        // left over from a killed app on launch.
        .onChange(of: WorkoutActivity.content(log: log, rest: restTimer, unit: unit), initial: true) {
            activity.sync()
        }
        // A new workout can start with the same content as the last one ("Workout", set 1).
        .onChange(of: log.active?.startedAt) {
            activity.sync()
        }
        // The Live Activity's Add Set button: the pop-up lives under Home's workout screen.
        .onChange(of: addSetRequest.isPending, initial: true) { _, isPending in
            if isPending {
                tab = .home
            }
        }
    }
}
