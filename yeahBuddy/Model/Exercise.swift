import SwiftData

/// The body area an exercise mainly trains. Drives grouping in the picker and tile colors.
enum MuscleGroup: String, Codable, CaseIterable, Identifiable {
    case chest, back, legs, shoulders, arms, core

    /// Stable identity for SwiftUI lists; the raw value is unique per case.
    var id: String { rawValue }
}

/// A movement the user can log, such as "Bench Press".
@Model
final class Exercise {
    /// The display name, e.g. "Bench Press".
    var name: String
    /// The main muscle group it trains.
    var muscle: MuscleGroup
    /// True for exercises the user created; false for the built-in catalog.
    var isCustom: Bool
    /// A short "how to do it" description shown on the exercise's detail page.
    /// Empty when the user didn't write one. The default lets stores saved before this
    /// field existed open without a migration.
    var summary: String = ""

    /// Creates an exercise.
    ///
    /// - Parameters:
    ///   - name: The display name.
    ///   - muscle: The main muscle group trained.
    ///   - isCustom: Whether the user created it. Built-in exercises leave this false.
    ///   - summary: A short description of how to do it. Optional.
    init(name: String, muscle: MuscleGroup, isCustom: Bool = false, summary: String = "") {
        self.name = name
        self.muscle = muscle
        self.isCustom = isCustom
        self.summary = summary
    }
}
