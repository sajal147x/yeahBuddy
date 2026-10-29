import SwiftUI

/// Each muscle group has its own color, the way teams do on a scoreboard.
extension MuscleGroup {
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

    var displayName: String {
        rawValue.capitalized
    }
}
