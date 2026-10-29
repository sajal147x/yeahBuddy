import SwiftUI

/// The Exercises tab: browse and search the whole library, and open any exercise to read
/// how to do it. Read-only; adding to a workout happens from the workout screen.
struct ExercisesView: View {
    @Environment(ExerciseCatalog.self) private var catalog
    // What the user has typed in the search field.
    @State private var searchText = ""

    /// Header, search field, then the grouped exercise cards.
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    ScreenHeader(title: "Exercises", subtitle: "\(catalog.all.count) exercises")
                    SearchField(text: $searchText, prompt: "Search exercises")
                    ExerciseSections(exercises: catalog.search(searchText))
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.lg)
            }
            // Dragging the list puts the keyboard away, like most search screens.
            .scrollDismissesKeyboard(.immediately)
            .background(Color.canvas)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: ExerciseDetailMode.self) { mode in
                // No add action: browsing never changes the workout.
                ExerciseDetailView(mode: mode, onAdd: nil)
            }
        }
    }
}
