import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

/// The workout in progress on the Lock Screen and in the Dynamic Island.
///
/// Everything that moves (workout clock, rest countdown, rest bar) is a system timer view, so
/// it ticks without the app running. The app only sends updates when something changes.
struct WorkoutLiveActivity: Widget {
    /// The Lock Screen banner plus the Dynamic Island's expanded, compact and minimal looks.
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            WorkoutLockScreenView(context: context)
                .activityBackgroundTint(Color.surface)
                .activitySystemActionForegroundColor(Color.textPrimary)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    ExerciseHeading(state: context.state)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    WorkoutClock(startedAt: context.attributes.startedAt)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        RestOrLastSet(state: context.state, isStale: context.isStale)
                        ActivityButtons(isResting: isResting(context))
                    }
                }
            } compactLeading: {
                Image(systemName: "dumbbell.fill")
                    .foregroundStyle(Color.brand)
            } compactTrailing: {
                CompactTime(context: context)
            } minimal: {
                CompactTime(context: context)
            }
            .keylineTint(Color.brand)
        }
    }
}

/// Whether a rest is counting down. A stale activity means the rest end has passed while the
/// app was asleep, so it's treated as not resting.
///
/// - Parameter context: The activity's current content.
/// - Returns: True while the countdown is running.
private func isResting(_ context: ActivityViewContext<WorkoutActivityAttributes>) -> Bool {
    if context.isStale {
        return false
    }
    return context.state.restEndsAt != nil
}

/// The span the workout clock counts over. A Live Activity lasts at most 8 hours, so the range
/// ends there; an open-ended range (to the distant future) made the Lock Screen hide the
/// seconds as "18:--".
///
/// - Parameter startedAt: When the workout started.
/// - Returns: Start to 8 hours later.
private func workoutClockRange(from startedAt: Date) -> ClosedRange<Date> {
    startedAt...startedAt.addingTimeInterval(8 * 60 * 60)
}

/// The Lock Screen banner: heading and clock, rest or last set, then the buttons.
private struct WorkoutLockScreenView: View {
    /// The activity's fixed attributes and current state.
    let context: ActivityViewContext<WorkoutActivityAttributes>

    /// Three rows, kept short to fit the Lock Screen's limited height.
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(alignment: .firstTextBaseline) {
                ExerciseHeading(state: context.state)
                Spacer()
                WorkoutClock(startedAt: context.attributes.startedAt)
            }
            RestOrLastSet(state: context.state, isStale: context.isStale)
            ActivityButtons(isResting: isResting(context))
        }
        .padding(Spacing.lg)
    }
}

/// "Bench Press · Set 4", or the workout title before any exercise is added.
private struct ExerciseHeading: View {
    /// The activity's current state.
    let state: WorkoutActivityAttributes.ContentState

    /// The exercise name with the next set number, on one line.
    var body: some View {
        if let name = state.exerciseName {
            Text("\(name) · Set \(state.nextSetNumber)")
                .font(.headline)
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)
        } else {
            Text(state.title)
                .font(.headline)
                .foregroundStyle(Color.textPrimary)
        }
    }
}

/// The workout's elapsed time, counting up by itself, e.g. "24:13".
private struct WorkoutClock: View {
    /// When the workout started.
    let startedAt: Date

    /// A system stopwatch, so it ticks without app updates. `timerInterval` (rather than the
    /// `.timer` date style) always reads as a clock; the date style switched to "15 minutes"
    /// on the Lock Screen.
    var body: some View {
        Text(timerInterval: workoutClockRange(from: startedAt), countsDown: false)
            .font(.label)
            .monospacedDigit()
            .foregroundStyle(Color.textSecondary)
            .multilineTextAlignment(.trailing)
            // Timer text otherwise claims the full width it might ever need.
            .frame(width: 72, alignment: .trailing)
    }
}

/// While resting: the countdown, "of 1:45", and a draining bar. Otherwise the last set.
private struct RestOrLastSet: View {
    /// The activity's current state.
    let state: WorkoutActivityAttributes.ContentState
    /// Whether the rest end has passed since the last update.
    let isStale: Bool

    /// The rest countdown, the last set, or nothing on a fresh exercise.
    var body: some View {
        if let endsAt = state.restEndsAt, !isStale {
            // The bar runs from when this rest began (its end minus its full length).
            let start = endsAt.addingTimeInterval(-state.restTotal)
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                    Text(timerInterval: start...endsAt, countsDown: true)
                        .font(.amount)
                        .foregroundStyle(Color.textPrimary)
                        .frame(maxWidth: 80, alignment: .leading)
                    Text("of \(Duration.seconds(state.restTotal).formatted(.time(pattern: .minuteSecond)))")
                        .font(.label)
                        .foregroundStyle(Color.textSecondary)
                }
                ProgressView(timerInterval: start...endsAt, countsDown: true) {
                    EmptyView()
                } currentValueLabel: {
                    EmptyView()
                }
                .tint(Color.brand)
            }
        } else if let lastSet = state.lastSet {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                Text("Last set")
                    .font(.label)
                    .foregroundStyle(Color.textSecondary)
                Text(lastSet)
                    .font(.amountSmall)
                    .foregroundStyle(Color.textPrimary)
            }
        }
    }
}

/// +15s and Skip while resting, and Add Set always.
private struct ActivityButtons: View {
    /// Whether rest is counting down; the rest buttons only make sense then.
    let isResting: Bool

    /// The buttons in a row, each running an App Intent in the app's process.
    var body: some View {
        HStack(spacing: Spacing.sm) {
            if isResting {
                Button(intent: ExtendRestIntent()) {
                    ChipLabel(title: "+15s", isProminent: false)
                }
                Button(intent: SkipRestIntent()) {
                    ChipLabel(title: "Skip", isProminent: false)
                }
            }
            Spacer(minLength: 0)
            Button(intent: OpenAddSetIntent()) {
                ChipLabel(title: "Add Set", isProminent: true)
            }
        }
        .buttonStyle(.plain)
    }
}

/// A capsule button face, matching the app's chips. The prominent one is brand-filled.
private struct ChipLabel: View {
    /// The button's text.
    let title: String
    /// Brand-filled (Add Set) or a quiet raised capsule (+15s, Skip).
    let isProminent: Bool

    /// The text on its capsule.
    var body: some View {
        if isProminent {
            Text(title)
                .font(.chip)
                .foregroundStyle(Color.onBrand)
                .padding(.horizontal, 14)
                .frame(minHeight: 34)
                .background(Color.brand, in: Capsule())
        } else {
            Text(title)
                .font(.chip)
                .foregroundStyle(Color.textPrimary)
                .padding(.horizontal, 14)
                .frame(minHeight: 34)
                .background(Color.surfaceRaised, in: Capsule())
        }
    }
}

/// The small time in the Dynamic Island: rest countdown while resting, else the workout clock.
private struct CompactTime: View {
    /// The activity's fixed attributes and current state.
    let context: ActivityViewContext<WorkoutActivityAttributes>

    /// A narrow system timer, so the island stays compact.
    var body: some View {
        if isResting(context), let endsAt = context.state.restEndsAt {
            Text(timerInterval: endsAt.addingTimeInterval(-context.state.restTotal)...endsAt, countsDown: true)
                .monospacedDigit()
                .foregroundStyle(Color.brand)
                .frame(maxWidth: 40)
        } else {
            Text(timerInterval: workoutClockRange(from: context.attributes.startedAt), countsDown: false)
                .monospacedDigit()
                .frame(maxWidth: 44)
        }
    }
}
