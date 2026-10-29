import SwiftUI

/// Searchable list of exercises grouped by muscle. Tapping one opens its detail page, where
/// the user adds it; typing a name that doesn't exist offers to create it.
struct ExercisePickerView: View {
    /// Called with the chosen (or newly created) exercise. The sheet closes itself after.
    let onPick: (Exercise) -> Void

    @Environment(ExerciseCatalog.self) private var catalog
    @Environment(\.dismiss) private var dismiss
    // What the user has typed in the search field.
    @State private var searchText = ""

    /// The search text without surrounding spaces; used as the name for a new exercise.
    private var trimmedSearch: String {
        searchText.trimmingCharacters(in: .whitespaces)
    }

    /// Whether to offer "Create …": only when something is typed and no exercise has
    /// exactly that name.
    private var canCreate: Bool {
        !trimmedSearch.isEmpty
            && !catalog.all.contains { $0.name.caseInsensitiveCompare(trimmedSearch) == .orderedSame }
    }

    /// An optional Create row, then one section per muscle group with any matches.
    var body: some View {
        NavigationStack {
            List {
                if canCreate {
                    createSection
                }
                let results = catalog.search(searchText)
                // Sections follow `MuscleGroup` order; empty groups are hidden.
                ForEach(MuscleGroup.allCases) { muscle in
                    let exercises = results.filter { $0.muscle == muscle }
                    if !exercises.isEmpty {
                        Section(muscle.displayName) {
                            ForEach(exercises) { exercise in
                                row(for: exercise)
                            }
                        }
                    }
                }
            }
            // Always shown so it's obvious you can type to create.
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search or create")
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            // Rows and the Create row push the detail page; the list (and the search text)
            // stay underneath, so Back returns to exactly where the user was.
            .navigationDestination(for: ExerciseDetailMode.self) { mode in
                ExerciseDetailView(mode: mode, onAdd: pick)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    /// A row that opens the create form, pre-filled with the typed name.
    private var createSection: some View {
        Section("New exercise") {
            NavigationLink(value: ExerciseDetailMode.create(name: trimmedSearch)) {
                Label("Create “\(trimmedSearch)”", systemImage: "plus.circle.fill")
            }
        }
    }

    /// One exercise: a muscle-colored dot, its name, and a CUSTOM tag if the user made it.
    ///
    /// - Parameter exercise: The exercise to show.
    /// - Returns: A row that opens the exercise's detail page. Nothing is added until the
    ///   user taps Add there.
    private func row(for exercise: Exercise) -> some View {
        NavigationLink(value: ExerciseDetailMode.existing(exercise)) {
            HStack(spacing: Spacing.md) {
                Circle()
                    .fill(exercise.muscle.tint)
                    .frame(width: 10, height: 10)
                Text(exercise.name)
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                if exercise.isCustom {
                    Text("CUSTOM")
                        .font(.tileLabel)
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
    }

    /// Hands the exercise to the caller and closes the whole sheet, not just the detail page.
    /// Passed to the detail page, because `dismiss` there would only pop back to the list.
    ///
    /// - Parameter exercise: The chosen exercise.
    private func pick(_ exercise: Exercise) {
        onPick(exercise)
        dismiss()
    }
}
