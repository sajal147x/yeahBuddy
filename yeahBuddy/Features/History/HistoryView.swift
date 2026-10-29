import SwiftUI

/// The History tab: every finished workout as a card, newest first.
struct HistoryView: View {
    @Environment(WorkoutLog.self) private var log
    @AppStorage("weightUnit") private var unit: WeightUnit = .kilograms

    /// "3 workouts" style summary under the title.
    private var subtitle: String {
        let count = log.history.count
        return count == 1 ? "1 workout" : "\(count) workouts"
    }

    /// Header, then the workout cards, or a placeholder when there are none yet.
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    ScreenHeader(title: "History", subtitle: subtitle)
                    if log.history.isEmpty {
                        ContentUnavailableView(
                            "No workouts yet",
                            systemImage: "dumbbell",
                            description: Text("Finished workouts show up here.")
                        )
                        .padding(.top, Spacing.xl)
                    }
                    ForEach(log.history) { workout in
                        NavigationLink(value: workout) {
                            WorkoutCard(
                                title: workout.title,
                                subtitle: workout.subtitle,
                                muscles: workout.muscleGroups,
                                stats: workout.stats(in: unit)
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
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Workout.self) { workout in
                WorkoutDetailView(workout: workout)
            }
        }
    }
}
