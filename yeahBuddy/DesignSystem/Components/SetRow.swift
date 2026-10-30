import SwiftUI

/// One logged set as a row: its number, then weight × reps, e.g. "1   82.5 kg × 8".
/// Optionally shows a delete button. Takes plain values so it works anywhere.
struct SetRow: View {
    /// The set's 1-based position within its exercise.
    let number: Int
    /// The formatted weight number, e.g. "82.5".
    let weight: String
    /// The weight unit, e.g. "kg".
    let unit: String
    /// How many reps were done.
    let reps: Int
    /// Called when the delete button is tapped. Nil hides the button (read-only rows).
    var onDelete: (() -> Void)? = nil
    /// Shows a check before the number, marking the set as done. Used in the live workout,
    /// where done sets sit next to the inputs for the next one; History leaves it off.
    var showsCheck = false

    /// Number badge, weight, ×, reps, and the delete button on the far right.
    var body: some View {
        HStack(spacing: Spacing.sm) {
            if showsCheck {
                Image(systemName: "checkmark")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(Color.brand)
                    .accessibilityHidden(true)
            }
            Text("\(number)")
                .font(.label.weight(.semibold))
                .foregroundStyle(Color.textSecondary)
                .frame(width: 24, height: 24)
                .background(Color.surfaceRaised, in: Circle())
            Text.amount(weight, unit: unit, size: 19)
                .foregroundStyle(Color.textPrimary)
            Text("×")
                .foregroundStyle(Color.textSecondary)
            Text.amount("\(reps)", size: 19)
                .foregroundStyle(Color.textPrimary)
            Spacer()
            if let onDelete {
                // Icon only to keep the row compact; the title stays for VoiceOver.
                Button("Delete Set", systemImage: "xmark", action: onDelete)
                    .labelStyle(.iconOnly)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.textSecondary)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
                    .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: Spacing.sm) {
        SetRow(number: 1, weight: "80", unit: "kg", reps: 8, onDelete: {}, showsCheck: true)
        SetRow(number: 2, weight: "82.5", unit: "kg", reps: 6)
    }
    .card()
    .padding()
    .background(Color.canvas)
}
