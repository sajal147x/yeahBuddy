import SwiftData

enum MuscleGroup: String, Codable, CaseIterable, Identifiable {
    case chest, back, legs, shoulders, arms, core

    var id: String { rawValue }
}

@Model
final class Exercise {
    var name: String
    var muscle: MuscleGroup
    /// True for exercises the user created; false for the built-in catalog.
    var isCustom: Bool

    init(name: String, muscle: MuscleGroup, isCustom: Bool = false) {
        self.name = name
        self.muscle = muscle
        self.isCustom = isCustom
    }
}
