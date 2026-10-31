import Foundation
import Observation
import SwiftData

/// Every exercise the user can pick: the built-in set plus their own.
///
/// Callers never deal with seeding or duplicates: the built-ins appear on first launch, and
/// adding a name that already exists hands back the existing exercise.
@Observable
final class ExerciseCatalog {
    /// Every exercise, sorted by name.
    private(set) var all: [Exercise] = []

    // Held so the store outlives every caller; a context alone does not keep it alive.
    private let container: ModelContainer
    // The main context, so changes are visible to SwiftUI immediately.
    private var context: ModelContext { container.mainContext }

    /// Loads the catalog, adding any built-in exercises the store doesn't have yet.
    ///
    /// - Parameter container: The store to read and write. The catalog keeps it alive.
    init(container: ModelContainer) {
        self.container = container
        all = fetchAll()
        addMissingBuiltIns()
        fillMissingBuiltInSummaries()
    }

    /// Adds every built-in the store is missing: all of them on first launch, and on later
    /// launches any added to `BuiltInExercises` since the install was made.
    ///
    /// Matching is by name, ignoring case, so an exercise the user already created under a
    /// built-in's name stands in for it rather than being duplicated.
    private func addMissingBuiltIns() {
        let existing = Set(all.map { $0.name.lowercased() })
        let missing = BuiltInExercises.all.filter { !existing.contains($0.name.lowercased()) }
        // Skip the disk write on every normal launch, where nothing is missing.
        if missing.isEmpty {
            return
        }
        for builtIn in missing {
            context.insert(Exercise(name: builtIn.name, muscle: builtIn.muscle, summary: builtIn.summary))
        }
        save()
        all = fetchAll()
    }

    /// Gives built-in exercises saved by an older version (before descriptions existed)
    /// their description from `BuiltInExercises`.
    ///
    /// Only built-ins with an empty description are touched, so custom exercises and any
    /// text already saved are never overwritten. Matching is by name.
    private func fillMissingBuiltInSummaries() {
        var changed = false
        for exercise in all where !exercise.isCustom && exercise.summary.isEmpty {
            if let builtIn = BuiltInExercises.all.first(where: { $0.name == exercise.name }) {
                exercise.summary = builtIn.summary
                changed = true
            }
        }
        // Skip the disk write on every normal launch, where nothing is missing.
        if changed {
            save()
        }
    }

    /// Exercises whose name contains `text`, ignoring case. Blank text matches everything.
    ///
    /// - Parameter text: What the user typed. Surrounding spaces are ignored.
    /// - Returns: Matching exercises, still sorted by name.
    func search(_ text: String) -> [Exercise] {
        let query = text.trimmingCharacters(in: .whitespaces)
        if query.isEmpty {
            return all
        }
        return all.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    /// Adds a user-made exercise. If one with the same name (ignoring case and surrounding
    /// spaces) already exists, that one is returned instead, so the catalog never holds
    /// duplicates. `name` must not be blank.
    ///
    /// - Parameters:
    ///   - name: The exercise name as typed. It is trimmed before saving.
    ///   - muscle: The muscle group it trains. Ignored when the name already exists.
    ///   - summary: An optional description. Trimmed, including stray line breaks.
    ///     Ignored when the name already exists.
    /// - Returns: The new exercise, or the existing one with that name.
    @discardableResult
    func addCustom(name: String, muscle: MuscleGroup, summary: String = "") -> Exercise {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let existing = all.first(where: { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            return existing
        }
        // Descriptions come from a multi-line field, so newlines are trimmed too.
        let trimmedSummary = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        let exercise = Exercise(name: trimmed, muscle: muscle, isCustom: true, summary: trimmedSummary)
        context.insert(exercise)
        save()
        // Re-sort in memory rather than fetching again; the list is small.
        all.append(exercise)
        all.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        return exercise
    }

    /// Reads every saved exercise from the store.
    ///
    /// - Returns: All exercises sorted by name, or an empty list if the fetch fails.
    private func fetchAll() -> [Exercise] {
        // The same reader-friendly order as `addCustom` uses: case-insensitive, so
        // "EZ Bar Curl" sorts before "External Rotation".
        let byName = FetchDescriptor<Exercise>(sortBy: [SortDescriptor(\.name, comparator: .localizedStandard)])
        return (try? context.fetch(byName)) ?? []
    }

    /// Writes pending changes to disk right away.
    private func save() {
        do {
            try context.save()
        } catch {
            // Nothing a caller could do about a failed save; flag it in debug builds only.
            assertionFailure("Saving exercises failed: \(error)")
        }
    }
}
