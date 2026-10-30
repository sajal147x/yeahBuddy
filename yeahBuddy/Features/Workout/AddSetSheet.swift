import SwiftUI

/// The pop-up for logging one set: weight and reps steppers, then Add Set.
///
/// Logging takes two deliberate taps (open this, then Add Set), so a stray tap on the card can
/// never record a set by accident. The values are bindings owned by the card, so the next time
/// the sheet opens it starts from the set just logged.
struct AddSetSheet: View {
    /// The exercise name, shown as the title.
    let exerciseName: String
    /// Which set this will be, e.g. 3 for the third set today.
    let setNumber: Int
    /// The unit to show and enter weights in.
    let unit: WeightUnit
    /// The final set from the last time this exercise was done, shown for reference.
    let previous: SetEntry?
    /// The weight to log, in `unit`.
    @Binding var weight: Double
    /// The reps to log.
    @Binding var reps: Double
    /// Called when Add Set is tapped. The sheet closes itself afterwards.
    let onAdd: () -> Void

    @Environment(\.dismiss) private var dismiss

    /// Title and set number, an optional "Last time" hint, the steppers, then Add Set.
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                if let previous {
                    Text("Last time: \(unit.format(kilograms: previous.weightKg)) × \(previous.reps)")
                        .font(.label)
                        .foregroundStyle(Color.textSecondary)
                }
                HStack(alignment: .top, spacing: Spacing.md) {
                    NumberStepper(value: $weight, step: unit.step, label: unit.rawValue)
                    NumberStepper(value: $reps, step: 1, label: "Reps", allowsDecimals: false, format: { "\(Int($0))" })
                }
                .card()
                Spacer(minLength: 0)
                Button("Add Set") {
                    onAdd()
                    dismiss()
                }
                .buttonStyle(.primary)
                // A set with zero reps isn't a set.
                .disabled(reps < 1)
            }
            .padding(Spacing.lg)
            .background(Color.canvas)
            .navigationTitle(exerciseName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .principal) {
                    // The exercise name with the set number under it, e.g. "Set 3".
                    VStack(spacing: 0) {
                        Text(exerciseName)
                            .font(.headline)
                            .foregroundStyle(Color.textPrimary)
                        Text("Set \(setNumber)")
                            .font(.label)
                            .foregroundStyle(Color.textSecondary)
                    }
                }
            }
            // The number pads have no return key; this gives them a Done button.
            .keyboardDoneButton()
        }
        // Half height: enough for the steppers and button, with the workout still visible.
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.canvas)
    }
}
