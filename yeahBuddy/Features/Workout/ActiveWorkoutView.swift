import SwiftUI

/// The full-screen workout in progress. Closes itself once the workout is finished or discarded.
struct ActiveWorkoutView: View {
    @Environment(WorkoutLog.self) private var log
    @Environment(RestTimer.self) private var restTimer
    @Environment(\.dismiss) private var dismiss
    // Shared with Home's settings menu through the same key.
    @AppStorage("weightUnit") private var unit: WeightUnit = .kilograms
    // Whether the exercise picker sheet is showing.
    @State private var pickingExercise = false
    // Whether the "Discard this workout?" dialog is showing.
    @State private var confirmingDiscard = false

    /// Scrolling tiles with Finish pinned to the bottom, plus the picker sheet and discard dialog.
    var body: some View {
        NavigationStack {
            ScrollView {
                // `active` is briefly nil after finishing, while the screen animates away.
                if let workout = log.active {
                    content(for: workout)
                }
            }
            .background(Color.canvas)
            // Finish stays reachable however long the workout gets.
            .safeAreaInset(edge: .bottom) {
                Button("Finish Workout") {
                    restTimer.skip()
                    log.finish()
                }
                .buttonStyle(.primary)
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.sm)
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
    /// - Returns: The stacked tiles.
    private func content(for workout: Workout) -> some View {
        VStack(spacing: Spacing.md) {
            HStack(spacing: Spacing.lg) {
                Stat(value: Text(workout.startedAt, style: .timer), label: "Time")
                Stat(value: unit.format(kilograms: workout.totalVolumeKg), label: "Volume")
                Stat(value: "\(workout.setCount)", label: "Sets")
            }
            .tile()
            RestBar()
            ForEach(workout.orderedEntries) { entry in
                ExerciseCard(entry: entry, unit: unit)
            }
            Button("Add Exercise", systemImage: "plus") {
                pickingExercise = true
            }
            .buttonStyle(.secondary)
        }
        .padding(Spacing.lg)
        // Cards slide in and out when exercises are added or removed.
        .animation(.snappy, value: workout.entries.count)
    }

    /// Minimize on the left (keeps the workout running), a More menu with Discard on the right.
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            // Only closes the screen; the workout stays live on the Home tile.
            Button("Minimize", systemImage: "chevron.down") {
                dismiss()
            }
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
                    onExtend: { restTimer.extend(by: 15) },
                    onSkip: { restTimer.skip() }
                )
                .transition(.scale(scale: 0.95).combined(with: .opacity))
            }
        }
        .animation(.snappy, value: restTimer.isRunning)
    }
}
