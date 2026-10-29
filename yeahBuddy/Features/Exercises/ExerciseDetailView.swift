import SwiftUI

/// What the exercise detail page is showing. Also the navigation value that opens it.
enum ExerciseDetailMode: Hashable {
    /// An exercise already in the catalog: read its details, then add it.
    case existing(Exercise)
    /// A new exercise the user is about to create, starting from the name they searched for.
    case create(name: String)
}

/// An exercise's page inside the picker: its name, muscle group and description, with a
/// button to add it to the workout. In create mode the same page becomes a small form.
///
/// Nothing is added to the workout until the button is tapped, so browsing is safe.
struct ExerciseDetailView: View {
    /// Whether this page shows an existing exercise or creates a new one.
    let mode: ExerciseDetailMode
    /// Called with the exercise to add, after the button is tapped. The picker closes itself.
    let onAdd: (Exercise) -> Void

    @Environment(ExerciseCatalog.self) private var catalog
    // The create-mode form fields. Unused when showing an existing exercise.
    @State private var name: String
    @State private var muscle: MuscleGroup = .chest
    @State private var summary = ""

    /// Creates the page.
    ///
    /// - Parameters:
    ///   - mode: The exercise to show, or the name to start a new one from.
    ///   - onAdd: Receives the exercise once the user taps the button.
    init(mode: ExerciseDetailMode, onAdd: @escaping (Exercise) -> Void) {
        self.mode = mode
        self.onAdd = onAdd
        // Pre-fill the name with what was typed in search, so creating takes fewer taps.
        switch mode {
        case .existing:
            _name = State(initialValue: "")
        case .create(let searchedName):
            _name = State(initialValue: searchedName)
        }
    }

    /// The name without surrounding spaces; blank means the create button stays disabled.
    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespaces)
    }

    /// The color of the page: the exercise's muscle, or the one picked in the form.
    private var tint: Color {
        switch mode {
        case .existing(let exercise):
            return exercise.muscle.tint
        case .create:
            return muscle.tint
        }
    }

    /// The details or the form, with the add button pinned to the bottom.
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                switch mode {
                case .existing(let exercise):
                    details(for: exercise)
                case .create:
                    createForm
                }
            }
            .padding(Spacing.lg)
        }
        .background(Color.canvas)
        // Pinned so it's always one thumb-reach away, however long the description is.
        .safeAreaInset(edge: .bottom) {
            addButton
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.sm)
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .animation(.snappy, value: muscle)
    }

    /// "New Exercise" when creating; empty otherwise because the hero tile shows the name.
    private var navigationTitle: String {
        switch mode {
        case .existing:
            return ""
        case .create:
            return "New Exercise"
        }
    }

    /// A big tile with the name and muscle group, then a tile with how to do it.
    ///
    /// - Parameter exercise: The exercise to show.
    /// - Returns: The stacked tiles.
    private func details(for exercise: Exercise) -> some View {
        Group {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(exercise.muscle.displayName.uppercased())
                    .font(.tileLabel)
                    .foregroundStyle(exercise.muscle.tint)
                Text(exercise.name)
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                if exercise.isCustom {
                    Text("CUSTOM")
                        .font(.tileLabel)
                        .foregroundStyle(Color.textSecondary)
                }
            }
            .tile(tint: exercise.muscle.tint)
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("HOW TO DO IT")
                    .font(.tileLabel)
                    .foregroundStyle(Color.textSecondary)
                // Custom exercises may have no description; say so rather than show a gap.
                Text(exercise.summary.isEmpty ? "No description yet." : exercise.summary)
                    .font(.body)
                    .foregroundStyle(exercise.summary.isEmpty ? Color.textSecondary : Color.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .tile()
        }
    }

    /// The create form: name, muscle group chips, and an optional description.
    private var createForm: some View {
        Group {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("NAME")
                    .font(.tileLabel)
                    .foregroundStyle(Color.textSecondary)
                TextField("Exercise name", text: $name)
                    .font(.tileTitle)
                    .textInputAutocapitalization(.words)
            }
            .tile(tint: tint)
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("MUSCLE GROUP")
                    .font(.tileLabel)
                    .foregroundStyle(Color.textSecondary)
                MuscleChips(selection: $muscle)
            }
            .tile()
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("HOW TO DO IT")
                    .font(.tileLabel)
                    .foregroundStyle(Color.textSecondary)
                // Grows with the text, up to a few lines, then scrolls inside itself.
                TextField("Optional", text: $summary, axis: .vertical)
                    .lineLimit(3...6)
            }
            .tile()
        }
    }

    /// "Add to Workout" for an existing exercise, "Create & Add" in create mode.
    private var addButton: some View {
        Button(addTitle, action: add)
            .buttonStyle(.primary(tint: tint))
            .disabled(isCreating && trimmedName.isEmpty)
    }

    /// Whether this page is the create form.
    private var isCreating: Bool {
        if case .create = mode {
            return true
        }
        return false
    }

    /// The add button's label for the current mode.
    private var addTitle: String {
        isCreating ? "Create & Add" : "Add to Workout"
    }

    /// Hands the exercise to the picker: the shown one, or a newly created one.
    private func add() {
        switch mode {
        case .existing(let exercise):
            onAdd(exercise)
        case .create:
            // If the name already exists the catalog returns that exercise instead of a
            // duplicate, so this is safe even if the user retyped a built-in name.
            onAdd(catalog.addCustom(name: trimmedName, muscle: muscle, summary: summary))
        }
    }
}
