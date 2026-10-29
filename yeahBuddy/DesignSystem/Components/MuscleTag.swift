import SwiftUI

/// A muscle group as a small colored dot and its name, e.g. "● Chest".
/// This is where muscle colors live now: small accents, not whole cards.
struct MuscleTag: View {
    /// The muscle group to show.
    let muscle: MuscleGroup

    /// The dot then the name, in the small label font.
    var body: some View {
        HStack(spacing: 6) {
            MuscleDot(muscle: muscle)
            Text(muscle.displayName)
                .font(.label)
                .foregroundStyle(Color.textSecondary)
        }
    }
}

/// Just the colored dot, for tight spots like list rows.
struct MuscleDot: View {
    /// The muscle group whose color to use.
    let muscle: MuscleGroup

    /// An 8pt circle in the muscle's color.
    var body: some View {
        Circle()
            .fill(muscle.tint)
            .frame(width: 8, height: 8)
    }
}

#Preview {
    VStack(alignment: .leading) {
        ForEach(MuscleGroup.allCases) { MuscleTag(muscle: $0) }
    }
    .card()
    .padding()
    .background(Color.canvas)
}
