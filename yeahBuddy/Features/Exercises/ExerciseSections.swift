import SwiftUI

/// Exercises grouped by muscle: a heading per muscle group and a card of rows under it.
/// Each row opens the exercise's detail page. Shared by the Exercises tab and the picker.
///
/// Rows are `NavigationLink`s to `ExerciseDetailMode`, so the screen using this must handle
/// that destination with `.navigationDestination(for: ExerciseDetailMode.self)`.
struct ExerciseSections: View {
    /// The exercises to show, e.g. the catalog's search results. Empty groups are hidden.
    let exercises: [Exercise]

    /// One heading and card per muscle group that has any exercises, in `MuscleGroup` order.
    var body: some View {
        ForEach(MuscleGroup.allCases) { muscle in
            let group = exercises.filter { $0.muscle == muscle }
            if !group.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    SectionTitle(muscle.displayName)
                    VStack(spacing: 0) {
                        ForEach(Array(group.enumerated()), id: \.element.id) { index, exercise in
                            // Hairline between rows, not above the first one.
                            if index > 0 {
                                Divider().overlay(Color.divider).padding(.leading, Spacing.lg)
                            }
                            row(for: exercise)
                        }
                    }
                    // Zero padding: rows pad themselves so their tap area reaches the edges.
                    .card(padding: 0)
                }
            }
        }
    }

    /// One exercise: its muscle dot, name, a Custom tag if the user made it, and a chevron.
    ///
    /// - Parameter exercise: The exercise to show.
    /// - Returns: A row that opens the exercise's detail page.
    private func row(for exercise: Exercise) -> some View {
        NavigationLink(value: ExerciseDetailMode.existing(exercise)) {
            HStack(spacing: Spacing.md) {
                MuscleDot(muscle: exercise.muscle)
                Text(exercise.name)
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                if exercise.isCustom {
                    Text("Custom")
                        .font(.label)
                        .foregroundStyle(Color.textSecondary)
                }
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.textSecondary)
            }
            .padding(.horizontal, Spacing.lg)
            .frame(minHeight: 52)
            // Makes the empty space in the row tappable too.
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
