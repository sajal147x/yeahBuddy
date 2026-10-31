import SwiftUI

/// Each muscle group keeps its own color: a small accent (dots and labels) in most places, and
/// the glow on live exercise cards (`MuscleGlowCard`). Kept in the design system so the model
/// stays UI-free.
extension MuscleGroup {
    /// The accent color for this muscle group's dot.
    var tint: Color {
        switch self {
        case .chest: return .red
        case .back: return .blue
        case .legs: return .green
        case .shoulders: return .orange
        case .arms: return .purple
        case .core: return .yellow
        }
    }

    /// The name shown to users, e.g. "Chest".
    var displayName: String {
        rawValue.capitalized
    }
}
