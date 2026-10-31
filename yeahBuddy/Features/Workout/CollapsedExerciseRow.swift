import SwiftUI

/// An exercise in the workout that isn't being logged right now, folded down to one row:
/// its name, muscle, and a short summary of what was done. Tapping it opens the full card.
///
/// Only one exercise is open at a time, so the one you're working on stays on screen
/// instead of being pushed down by the steppers of everything before it.
struct CollapsedExerciseRow: View {
    /// The exercise entry to summarize.
    let entry: ExerciseEntry
    /// The unit to show weights in.
    let unit: WeightUnit
    /// Called when the row is tapped, to open this exercise's full card.
    let onExpand: () -> Void

    /// The muscle pill and chevron on top, the exercise name centered with its summary under
    /// it, on a card lit by the muscle color: a shorter version of the open card.
    var body: some View {
        Button(action: onExpand) {
            VStack(spacing: Spacing.sm) {
                HStack {
                    if let muscle = entry.exercise?.muscle {
                        MusclePill(muscle: muscle)
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color.textSecondary)
                }
                VStack(spacing: 2) {
                    Text(entry.exercise?.name ?? "Exercise")
                        .font(.cardTitle)
                        .foregroundStyle(Color.textPrimary)
                        .multilineTextAlignment(.center)
                    Text(summary)
                        .font(.label)
                        .foregroundStyle(Color.textSecondary)
                }
                .frame(maxWidth: .infinity)
            }
            // The whole card is the tap target, not just the text.
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .muscleGlowCard(entry.exercise?.muscle)
        .accessibilityHint("Double tap to show sets and log more")
    }

    /// What was done so far, e.g. "3 sets · 135 lb × 5" (the last set), or "No sets yet".
    private var summary: String {
        let sets = entry.orderedSets
        guard let last = sets.last else {
            return "No sets yet"
        }
        var count = "\(sets.count) sets"
        if sets.count == 1 {
            count = "1 set"
        }
        return "\(count) · \(unit.format(kilograms: last.weightKg)) × \(last.reps)"
    }
}
