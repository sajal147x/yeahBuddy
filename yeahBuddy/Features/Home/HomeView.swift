import SwiftUI

/// The scoreboard: the live workout on top, then past workouts as tiles.
struct HomeView: View {
    @Environment(WorkoutLog.self) private var log
    // The user's kg/lb choice, saved in UserDefaults and shared by every screen.
    @AppStorage("weightUnit") private var unit: WeightUnit = .kilograms
    // Whether the full-screen active workout is showing.
    @State private var showingWorkout = false

    /// Live tile or Start button, then the Recent feed, with settings in the toolbar.
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    currentWorkout
                    Text("Recent")
                        .font(.tileTitle)
                        .padding(.top, Spacing.md)
                    if log.history.isEmpty {
                        ContentUnavailableView(
                            "No workouts yet",
                            systemImage: "dumbbell",
                            description: Text("Finished workouts show up here.")
                        )
                    }
                    ForEach(log.history) { workout in
                        NavigationLink(value: workout) {
                            WorkoutTile(
                                title: workout.title,
                                subtitle: workout.subtitle,
                                stats: workout.stats(in: unit),
                                tint: workout.tint
                            )
                        }
                        // Plain style so the tile keeps its own colors instead of link blue.
                        .buttonStyle(.plain)
                    }
                }
                .padding(Spacing.lg)
            }
            .background(Color.canvas)
            .navigationTitle("yeahBuddy")
            .navigationDestination(for: Workout.self) { workout in
                WorkoutDetailView(workout: workout)
            }
            .toolbar {
                Menu("Settings", systemImage: "gearshape") {
                    Picker("Units", selection: $unit) {
                        ForEach(WeightUnit.allCases) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $showingWorkout) {
                ActiveWorkoutView()
            }
        }
    }

    /// The LIVE tile when a workout is running (tap to reopen it), otherwise Start Workout.
    @ViewBuilder
    private var currentWorkout: some View {
        if let workout = log.active {
            Button {
                showingWorkout = true
            } label: {
                LiveWorkoutTile(
                    title: workout.title,
                    startedAt: workout.startedAt,
                    setCount: workout.setCount,
                    tint: workout.tint
                )
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
}
