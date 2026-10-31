import SwiftUI

/// The Home tab: today's workout (or a Start button), this week's totals, and the last
/// finished workout.
struct HomeView: View {
    @Environment(WorkoutLog.self) private var log
    // The user's kg/lb choice, saved in UserDefaults and shared by every screen.
    @AppStorage("weightUnit") private var unit: WeightUnit = .kilograms
    // The app-wide appearance choice, shared with RootView.
    @AppStorage("appearance") private var appearance: AppAppearance = .system
    // Whether the full-screen active workout is showing.
    @State private var showingWorkout = false
    @Environment(AddSetRequest.self) private var addSetRequest

    /// Header, current workout, This Week, then Last Workout.
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    ScreenHeader(title: "Today", subtitle: Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day())) {
                        settingsMenu
                    }
                    currentWorkout
                    SectionTitle("This week")
                    thisWeek
                    if let last = log.history.first {
                        SectionTitle("Last workout")
                        NavigationLink(value: last) {
                            WorkoutCard(
                                title: last.title,
                                subtitle: last.subtitle,
                                muscles: last.muscleGroups,
                                stats: last.stats(in: unit)
                            )
                        }
                        // Plain style so the card keeps its own colors instead of link tint.
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.lg)
            }
            .background(Color.canvas)
            // The big ScreenHeader replaces the navigation bar on this root screen.
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Workout.self) { workout in
                WorkoutDetailView(workout: workout)
            }
            .fullScreenCover(isPresented: $showingWorkout) {
                ActiveWorkoutView()
            }
            // The Live Activity's Add Set button: open the workout, which takes it from there.
            .onChange(of: addSetRequest.isPending, initial: true) { _, isPending in
                if isPending {
                    openWorkoutForAddSet()
                }
            }
        }
    }

    /// The round gear button that opens unit and appearance settings.
    private var settingsMenu: some View {
        Menu {
            Picker("Units", selection: $unit) {
                ForEach(WeightUnit.allCases) { unit in
                    Text(unit.rawValue).tag(unit)
                }
            }
            Picker("Appearance", selection: $appearance) {
                ForEach(AppAppearance.allCases, id: \.self) { appearance in
                    Text(appearance.rawValue).tag(appearance)
                }
            }
        } label: {
            CircleIcon(systemImage: "gearshape")
        }
        .accessibilityLabel("Settings")
    }

    /// The live workout card when one is running (tap to reopen it), otherwise Start Workout.
    @ViewBuilder
    private var currentWorkout: some View {
        if let workout = log.active {
            Button {
                showingWorkout = true
            } label: {
                LiveWorkoutCard(title: workout.title, startedAt: workout.startedAt, setCount: workout.setCount)
            }
            .buttonStyle(.plain)
        } else {
            Button("Start Workout", systemImage: "play.fill") {
                log.start()
                showingWorkout = true
            }
            .buttonStyle(.primary)
        }
    }

    /// Workouts, sets and volume for the current week, in one card.
    private var thisWeek: some View {
        let week = log.thisWeek()
        return HStack(alignment: .top) {
            Stat(StatValue(number: "\(week.workouts)", label: week.workouts == 1 ? "Workout" : "Workouts"))
            Stat(StatValue(number: "\(week.sets)", label: "Sets"))
            Stat(StatValue(number: unit.formatNumber(kilograms: week.volumeKg), unit: unit.rawValue, label: "Volume"))
        }
        .card()
    }

    /// Opens the workout screen for the Live Activity's Add Set button. With no workout in
    /// progress (the activity was out of date) there's nothing to add to, so drop the request.
    private func openWorkoutForAddSet() {
        if log.active != nil {
            showingWorkout = true
        } else {
            addSetRequest.isPending = false
        }
    }
}
