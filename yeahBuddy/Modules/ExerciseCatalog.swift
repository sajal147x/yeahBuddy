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

    /// Loads the catalog, adding the built-in exercises on first launch.
    ///
    /// - Parameter container: The store to read and write. The catalog keeps it alive.
    init(container: ModelContainer) {
        self.container = container
        all = fetchAll()
        // An empty store means first launch: an install always has the built-ins after
        // this, so "empty" never happens again.
        if all.isEmpty {
            for builtIn in BuiltInExercises.all {
                context.insert(Exercise(name: builtIn.name, muscle: builtIn.muscle))
            }
            save()
            all = fetchAll()
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
    /// - Returns: The new exercise, or the existing one with that name.
    @discardableResult
    func addCustom(name: String, muscle: MuscleGroup) -> Exercise {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let existing = all.first(where: { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            return existing
        }
        let exercise = Exercise(name: trimmed, muscle: muscle, isCustom: true)
        context.insert(exercise)
        save()
        // Re-sort in memory rather than fetching again; the list is small.
        all.append(exercise)
        all.sort { $0.name < $1.name }
        return exercise
    }

    /// Reads every saved exercise from the store.
    ///
    /// - Returns: All exercises sorted by name, or an empty list if the fetch fails.
    private func fetchAll() -> [Exercise] {
        let byName = FetchDescriptor<Exercise>(sortBy: [SortDescriptor(\.name)])
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
