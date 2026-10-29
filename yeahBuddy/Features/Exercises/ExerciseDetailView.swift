import SwiftUI

/// What the exercise detail page is showing. Also the navigation value that opens it.
enum ExerciseDetailMode: Hashable {
    /// An exercise already in the catalog: read its details, then (optionally) add it.
    case existing(Exercise)
    /// A new exercise the user is about to create, starting from the name they searched for.
    case create(name: String)
}

/// An exercise's page: its name, muscle group and description, with a button to add it to
/// the workout. In create mode the same page becomes a small form.
///
/// Nothing is added to the workout until the button is tapped, so browsing is safe.
struct ExerciseDetailView: View {
    /// Whether this page shows an existing exercise or creates a new one.
    let mode: ExerciseDetailMode
    /// Called with the exercise to add, after the button is tapped. Nil when browsing from
    /// the Exercises tab, which hides the button: that page is read-only.
    let onAdd: ((Exercise) -> Void)?

    @Environment(ExerciseCatalog.self) private var catalog
    // The create-mode form fields. Unused when showing an existing exercise.
    @State private var name: String
    @State private var muscle: MuscleGroup = .chest
    @State private var summary = ""

    /// Creates the page.
    ///
    /// - Parameters:
    ///   - mode: The exercise to show, or the name to start a new one from.
    ///   - onAdd: Receives the exercise once the user taps the button, or nil for read-only.
    init(mode: ExerciseDetailMode, onAdd: ((Exercise) -> Void)?) {
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

    /// The details or the form, with the add button pinned to the bottom when there is one.
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
        .scrollDismissesKeyboard(.interactively)
        .background(Color.canvas)
        // Pinned so it's always one thumb-reach away, however long the description is.
        .safeAreaInset(edge: .bottom) {
            if onAdd != nil {
                addButton
                    .padding(.horizontal, Spacing.lg)
                    .padding(.bottom, Spacing.sm)
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    /// "New Exercise" when creating; empty otherwise because the first card shows the name.
    private var navigationTitle: String {
        switch mode {
        case .existing:
            return ""
        case .create:
            return "New Exercise"
        }
    }

    /// A card with the muscle tag and big name, then a card with how to do it.
    ///
    /// - Parameter exercise: The exercise to show.
    /// - Returns: The stacked cards.
    private func details(for exercise: Exercise) -> some View {
        Group {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    MuscleTag(muscle: exercise.muscle)
                    if exercise.isCustom {
                        Text("· Custom")
                            .font(.label)
                            .foregroundStyle(Color.textSecondary)
                    }
                }
                Text(exercise.name)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
            }
            .card()
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("How to do it")
                    .font(.label.weight(.semibold))
                    .foregroundStyle(Color.brand)
                // Custom exercises may have no description; say so rather than show a gap.
                Text(exercise.summary.isEmpty ? "No description yet." : exercise.summary)
                    .font(.body)
                    .foregroundStyle(exercise.summary.isEmpty ? Color.textSecondary : Color.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .card()
        }
    }

    /// The create form: name, muscle group chips, and an optional description.
    private var createForm: some View {
        Group {
            formCard(label: "Name") {
                TextField("Exercise name", text: $name)
                    .font(.cardTitle)
                    .foregroundStyle(Color.textPrimary)
                    .textInputAutocapitalization(.words)
            }
            formCard(label: "Muscle group") {
                MuscleChips(selection: $muscle)
            }
            formCard(label: "How to do it") {
                // Grows with the text, up to a few lines, then scrolls inside itself.
                TextField("Optional", text: $summary, axis: .vertical)
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(3...6)
            }
        }
    }

    /// A card with a small brand-colored label above some form content.
    ///
    /// - Parameters:
    ///   - label: The field's name, e.g. "Name".
    ///   - content: The field itself.
    /// - Returns: The labelled card.
    private func formCard(label: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(label)
                .font(.label.weight(.semibold))
                .foregroundStyle(Color.brand)
            content()
        }
        .card()
    }

    /// "Add to Workout" for an existing exercise, "Create & Add" in create mode.
    private var addButton: some View {
        Button(addTitle, action: add)
            .buttonStyle(.primary)
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

    /// Hands the exercise to the caller: the shown one, or a newly created one.
    private func add() {
        guard let onAdd else {
            return
        }
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
