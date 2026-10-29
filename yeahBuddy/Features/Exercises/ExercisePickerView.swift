import SwiftUI

/// Searchable list of exercises grouped by muscle. Typing a name that doesn't exist offers
/// to create it.
struct ExercisePickerView: View {
    let onPick: (Exercise) -> Void

    @Environment(ExerciseCatalog.self) private var catalog
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var trimmedSearch: String {
        searchText.trimmingCharacters(in: .whitespaces)
    }

    private var canCreate: Bool {
        !trimmedSearch.isEmpty
            && !catalog.all.contains { $0.name.caseInsensitiveCompare(trimmedSearch) == .orderedSame }
    }

    var body: some View {
        NavigationStack {
            List {
                if canCreate {
                    createSection
                }
                let results = catalog.search(searchText)
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
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search or create")
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var createSection: some View {
        Section("New exercise") {
            Menu {
                ForEach(MuscleGroup.allCases) { muscle in
                    Button(muscle.displayName) {
                        pick(catalog.addCustom(name: trimmedSearch, muscle: muscle))
                    }
                }
            } label: {
                Label("Create “\(trimmedSearch)”", systemImage: "plus.circle.fill")
            }
        }
    }

    private func row(for exercise: Exercise) -> some View {
        Button {
            pick(exercise)
        } label: {
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

    private func pick(_ exercise: Exercise) {
        onPick(exercise)
        dismiss()
    }
}
