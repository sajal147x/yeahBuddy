import Foundation
import Observation
import SwiftData

/// Every exercise the user can pick: the built-in set plus their own.
@Observable
final class ExerciseCatalog {
    /// Sorted by name.
    private(set) var all: [Exercise] = []

    // Held so the store outlives every caller; a context alone does not keep it alive.
    private let container: ModelContainer
    private var context: ModelContext { container.mainContext }

    /// Loads the catalog, adding the built-in exercises on first launch.
    init(container: ModelContainer) {
        self.container = container
        all = fetchAll()
        if all.isEmpty {
            for builtIn in BuiltInExercises.all {
                context.insert(Exercise(name: builtIn.name, muscle: builtIn.muscle))
            }
            save()
            all = fetchAll()
        }
    }

    /// Exercises whose name contains `text`, ignoring case. Blank text matches everything.
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
    @discardableResult
    func addCustom(name: String, muscle: MuscleGroup) -> Exercise {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let existing = all.first(where: { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            return existing
        }
        let exercise = Exercise(name: trimmed, muscle: muscle, isCustom: true)
        context.insert(exercise)
        save()
        all.append(exercise)
        all.sort { $0.name < $1.name }
        return exercise
    }

    private func fetchAll() -> [Exercise] {
        let byName = FetchDescriptor<Exercise>(sortBy: [SortDescriptor(\.name)])
        return (try? context.fetch(byName)) ?? []
    }

    private func save() {
        do {
            try context.save()
        } catch {
            assertionFailure("Saving exercises failed: \(error)")
        }
    }
}
