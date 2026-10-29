import SwiftUI

/// The sheet for adding an exercise to the workout. Tapping one opens its detail page, where
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

    /// An optional Create card, then the grouped exercise cards.
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    if canCreate {
                        createCard
                    }
                    ExerciseSections(exercises: catalog.search(searchText))
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.lg)
            }
            .scrollDismissesKeyboard(.immediately)
            .background(Color.canvas)
            // Always shown so it's obvious you can type to create.
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search or create")
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            // Rows and the Create card push the detail page; the list (and the search text)
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

    /// A card that opens the create form, pre-filled with the typed name.
    private var createCard: some View {
        NavigationLink(value: ExerciseDetailMode.create(name: trimmedSearch)) {
            HStack(spacing: Spacing.md) {
                Image(systemName: "plus")
                    .font(.headline)
                    .foregroundStyle(Color.onBrand)
                    .frame(width: 32, height: 32)
                    .background(Color.brand, in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text("Create “\(trimmedSearch)”")
                        .font(.headline)
                        .foregroundStyle(Color.textPrimary)
                    Text("New custom exercise")
                        .font(.label)
                        .foregroundStyle(Color.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.textSecondary)
            }
            .card()
        }
        .buttonStyle(.plain)
        .padding(.top, Spacing.sm)
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
