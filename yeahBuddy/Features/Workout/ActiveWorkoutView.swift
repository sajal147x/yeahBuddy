import SwiftUI

/// The full-screen workout in progress. Closes itself once the workout is finished or discarded.
struct ActiveWorkoutView: View {
    @Environment(WorkoutLog.self) private var log
    @Environment(ExerciseCatalog.self) private var catalog
    @Environment(RestTimer.self) private var restTimer
    @Environment(\.dismiss) private var dismiss
    @Environment(AddSetRequest.self) private var addSetRequest
    // Shared with Home's settings menu through the same key.
    @AppStorage("weightUnit") private var unit: WeightUnit = .kilograms
    // Whether the exercise picker sheet is showing.
    @State private var pickingExercise = false
    // Whether the "Discard this workout?" dialog is showing.
    @State private var confirmingDiscard = false
    // Which exercise shows as a full card; the rest are collapsed rows. A freshly opened
    // screen shows the newest.
    @State private var open: OpenExercise = .newest
    // The voice action in progress, if any, and its result banner.
    @State private var voice = VoiceController()

    /// The choices for which exercise card is open. At most one is open at a time.
    private enum OpenExercise {
        /// The most recently added exercise, e.g. right after adding one.
        case newest
        /// One the user tapped open.
        case entry(ExerciseEntry)
        /// Everything folded, after the user collapsed the open card.
        case none
    }

    /// Scrolling cards with Finish in the top bar, plus the picker sheet and discard dialog.
    var body: some View {
        NavigationStack {
            ScrollView {
                // `active` is briefly nil after finishing, while the screen animates away.
                if let workout = log.active {
                    content(for: workout)
                }
            }
            .background(Color.canvas)
            // Any scroll puts the keyboard away, so typing a weight never traps the screen.
            .scrollDismissesKeyboard(.immediately)
            // The steppers' number pads have no return key; this gives them one Done button.
            .keyboardDoneButton()
            // The mic sits where the thumb rests. Hidden where the on-device model can't run
            // (older iPhones, Apple Intelligence off), since voice can't work there.
            .safeAreaInset(edge: .bottom) {
                if VoiceController.isAvailable {
                    VoiceBar(controller: voice, onListen: listen, onUndo: {
                        voice.undo(using: VoiceLogger(log: log, catalog: catalog))
                        // Rest was started for the sets that are now gone.
                        restTimer.skip()
                    })
                }
            }
            .navigationTitle(log.active?.title ?? "Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
            .sheet(isPresented: $pickingExercise) {
                ExercisePickerView { exercise in
                    log.add(exercise)
                }
            }
            .confirmationDialog("Discard this workout?", isPresented: $confirmingDiscard, titleVisibility: .visible) {
                Button("Discard Workout", role: .destructive) {
                    if let workout = log.active {
                        restTimer.skip()
                        log.delete(workout)
                    }
                }
            } message: {
                Text("All sets logged in it will be deleted.")
            }
            // The Live Activity's Add Set button: open the exercise being worked on, whose
            // card then shows the pop-up. With no exercise yet, there's nothing to add to.
            .onChange(of: addSetRequest.isPending, initial: true) { _, isPending in
                if isPending {
                    if let current = log.currentEntry {
                        open = .entry(current)
                    } else {
                        addSetRequest.isPending = false
                    }
                }
            }
            // Finishing or discarding clears `active`; that is the signal to close.
            .onChange(of: log.active == nil) { _, ended in
                if ended {
                    dismiss()
                }
            }
        }
    }

    /// The scrolling content for a workout: scores, rest timer, exercise cards, Add Exercise.
    ///
    /// - Parameter workout: The workout in progress.
    /// - Returns: The stacked cards.
    private func content(for workout: Workout) -> some View {
        VStack(spacing: Spacing.md) {
            HStack(alignment: .top, spacing: Spacing.lg) {
                Stat(value: Text(workout.startedAt, style: .timer).font(.amount), label: "Time")
                Stat(StatValue(number: unit.formatNumber(kilograms: workout.totalVolumeKg), unit: unit.rawValue, label: "Volume"))
                Stat(StatValue(number: "\(workout.setCount)", label: "Sets"))
            }
            .card()
            RestBar()
            ForEach(workout.orderedEntries) { entry in
                // `===` compares the model objects themselves, so this view doesn't need
                // SwiftData for their identifiers.
                if entry === openEntry(in: workout) {
                    ExerciseCard(entry: entry, unit: unit, previous: previousSet(for: entry)) {
                        withAnimation(.snappy) {
                            open = .none
                        }
                    }
                } else {
                    CollapsedExerciseRow(entry: entry, unit: unit) {
                        withAnimation(.snappy) {
                            open = .entry(entry)
                        }
                    }
                }
            }
            Button("Add Exercise", systemImage: "plus") {
                pickingExercise = true
            }
            .buttonStyle(.secondary)
        }
        .padding(Spacing.lg)
        // Cards slide in and out when exercises are added or removed.
        .animation(.snappy, value: workout.entries.count)
        .onChange(of: workout.entries.count) { oldCount, newCount in
            // A newly added exercise is the one about to be logged, so open it and fold
            // the others. Removing one keeps whatever was open, if it's still there.
            if newCount > oldCount {
                open = .newest
            }
        }
    }

    /// Which exercise shows as a full card.
    ///
    /// - Parameter workout: The workout in progress.
    /// - Returns: The open exercise, or nil when everything is collapsed. A tapped exercise
    ///   that has since been removed falls back to the newest one.
    private func openEntry(in workout: Workout) -> ExerciseEntry? {
        switch open {
        case .newest:
            return workout.orderedEntries.last
        case .entry(let entry):
            if workout.entries.contains(where: { $0 === entry }) {
                return entry
            }
            return workout.orderedEntries.last
        case .none:
            return nil
        }
    }

    /// Starts a voice action: listen, parse, log, and start rest like a tapped set would.
    private func listen() {
        let context = ParseContext(
            currentExercise: log.currentEntry?.exercise?.name,
            unit: unit,
            exerciseNames: catalog.all.map(\.name)
        )
        voice.start(logger: VoiceLogger(log: log, catalog: catalog), context: context, unit: unit) {
            restTimer.start(seconds: ExerciseCard.restSeconds)
        }
    }

    /// Where this exercise left off last session, for pre-filling its card.
    ///
    /// - Parameter entry: An exercise in the workout in progress.
    /// - Returns: The final set from the last finished workout with that exercise, or nil if
    ///   it has never been done (or its exercise was deleted from the catalog).
    private func previousSet(for entry: ExerciseEntry) -> SetEntry? {
        if let exercise = entry.exercise {
            return log.lastSet(of: exercise)
        }
        return nil
    }

    /// Minimize on the left (keeps the workout running); Finish and a More menu with Discard
    /// on the right.
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            // Only closes the screen; the workout stays live on the Home tile.
            Button("Minimize", systemImage: "chevron.down") {
                dismiss()
            }
        }
        // Up here rather than pinned to the bottom, where it covered Log Set and the steppers.
        // It's needed once per workout, so it doesn't earn space beside the logging controls.
        ToolbarItem(placement: .topBarTrailing) {
            Button("Finish") {
                restTimer.skip()
                log.finish()
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.brand)
            .fontWeight(.semibold)
        }
        ToolbarItem(placement: .topBarTrailing) {
            Menu("More", systemImage: "ellipsis") {
                Button("Discard Workout", systemImage: "trash", role: .destructive) {
                    confirmingDiscard = true
                }
            }
        }
    }
}

/// Shows the rest countdown while it runs, redrawing every second.
///
/// `RestTimer` stores an end time rather than ticking, so something has to ask for a redraw;
/// `TimelineView` does that once a second and only while this view is on screen.
private struct RestBar: View {
    @Environment(RestTimer.self) private var restTimer

    /// The countdown tile while resting, nothing otherwise.
    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { _ in
            if restTimer.isRunning {
                RestCountdown(
                    remaining: restTimer.remaining,
                    total: restTimer.total,
                    onExtend: { restTimer.extend(by: 15) },
                    onSkip: { restTimer.skip() }
                )
                .transition(.scale(scale: 0.95).combined(with: .opacity))
            }
        }
        .animation(.snappy, value: restTimer.isRunning)
    }
}
