import SwiftUI

/// The full-screen workout in progress. Closes itself once the workout is finished or discarded.
struct ActiveWorkoutView: View {
    @Environment(WorkoutLog.self) private var log
    @Environment(RestTimer.self) private var restTimer
    @Environment(\.dismiss) private var dismiss
    @AppStorage("weightUnit") private var unit: WeightUnit = .kilograms
    @State private var pickingExercise = false
    @State private var confirmingDiscard = false

    var body: some View {
        NavigationStack {
            ScrollView {
                if let workout = log.active {
                    content(for: workout)
                }
            }
            .background(Color.canvas)
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
            .onChange(of: log.active == nil) { _, ended in
                if ended {
                    dismiss()
                }
            }
        }
    }

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
        .animation(.snappy, value: workout.entries.count)
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
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
private struct RestBar: View {
    @Environment(RestTimer.self) private var restTimer

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
