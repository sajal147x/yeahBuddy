import SwiftUI

/// How a workout is labelled on tiles. Kept out of the model so the model stays UI-free.
extension Workout {
    /// The muscle groups trained, in the order first trained, e.g. "Chest · Legs".
    /// Falls back to "Workout" before any exercise is added.
    var title: String {
        let names = muscleGroups.map(\.displayName)
        return names.isEmpty ? "Workout" : names.joined(separator: " · ")
    }

    /// The color of the first muscle group trained, or the accent color if none yet.
    var tint: Color {
        muscleGroups.first?.tint ?? .accentColor
    }

    /// e.g. "Tue, Oct 28 · 52 min". Only the date while in progress.
    var subtitle: String {
        let date = startedAt.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
        guard let endedAt else {
            return date
        }
        // Whole minutes, rounded down: a 52 min 40 s workout reads "52 min".
        let minutes = Int(endedAt.timeIntervalSince(startedAt) / 60)
        return "\(date) · \(minutes) min"
    }

    /// The scores shown on history tiles and the detail screen.
    ///
    /// - Parameter unit: The unit to show volume in.
    /// - Returns: Volume, set count and exercise count, as value and label pairs.
    func stats(in unit: WeightUnit) -> [(value: String, label: String)] {
        [
            (unit.format(kilograms: totalVolumeKg), "Volume"),
            ("\(setCount)", "Sets"),
            ("\(entries.count)", "Exercises"),
        ]
    }

    /// Distinct muscle groups in the order they were first trained.
    private var muscleGroups: [MuscleGroup] {
        // A plain loop rather than a Set, because order matters for the title.
        var seen: [MuscleGroup] = []
        for entry in orderedEntries {
            if let muscle = entry.exercise?.muscle, !seen.contains(muscle) {
                seen.append(muscle)
            }
        }
        return seen
    }
}
