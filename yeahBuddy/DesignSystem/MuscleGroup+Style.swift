import SwiftUI

/// Each muscle group has its own color, the way teams do on a scoreboard.
/// Kept in the design system so the model stays free of UI concerns.
extension MuscleGroup {
    /// The color used for tiles, dots and buttons tied to this muscle group.
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
