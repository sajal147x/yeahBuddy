import SwiftUI

/// How a workout is labelled on tiles. Kept out of the model so the model stays UI-free.
extension Workout {
    /// The muscle groups trained, in the order first trained, e.g. "Chest · Legs".
    var title: String {
        let names = muscleGroups.map(\.displayName)
        return names.isEmpty ? "Workout" : names.joined(separator: " · ")
    }

    /// The color of the first muscle group trained.
    var tint: Color {
        muscleGroups.first?.tint ?? .accentColor
    }

    /// e.g. "Tue, Oct 28 · 52 min". Only the date while in progress.
    var subtitle: String {
        let date = startedAt.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
        guard let endedAt else {
            return date
        }
        let minutes = Int(endedAt.timeIntervalSince(startedAt) / 60)
        return "\(date) · \(minutes) min"
    }

    func stats(in unit: WeightUnit) -> [(value: String, label: String)] {
        [
            (unit.format(kilograms: totalVolumeKg), "Volume"),
            ("\(setCount)", "Sets"),
            ("\(entries.count)", "Exercises"),
        ]
    }

    private var muscleGroups: [MuscleGroup] {
        var seen: [MuscleGroup] = []
        for entry in orderedEntries {
            if let muscle = entry.exercise?.muscle, !seen.contains(muscle) {
                seen.append(muscle)
            }
        }
        return seen
    }
}
