import SwiftData
import Testing
@testable import yeahBuddy

/// Behavior of `ExerciseCatalog`: seeding, search and custom exercises.
@MainActor
struct ExerciseCatalogTests {
    /// A fresh in-memory store for each test.
    let store = TestStore()

    /// Built-ins are added exactly once, however many times the catalog is opened.
    @Test func firstLaunchProvidesBuiltInExercisesOnce() {
        let first = ExerciseCatalog(container: store.container)
        let second = ExerciseCatalog(container: store.container)

        #expect(first.all.contains { $0.name == "Bench Press" && $0.muscle == .chest })
        #expect(second.all.count == first.all.count)
        #expect(first.all.map(\.name) == first.all.map(\.name).sorted())
    }

    /// Search finds partial, any-case matches; blank search shows everything.
    @Test func searchMatchesAnyPartOfTheNameIgnoringCase() {
        let catalog = ExerciseCatalog(container: store.container)

        #expect(catalog.search("CURL").map(\.name) == [
            "Barbell Curl", "Dumbbell Curl", "Hammer Curl", "Leg Curl",
        ])
        #expect(catalog.search("  ").count == catalog.all.count)
    }

    /// Custom names are trimmed and sorted in, and an existing name is never duplicated.
    @Test func customExercisesJoinTheCatalogWithoutDuplicates() {
        let catalog = ExerciseCatalog(container: store.container)
        let countBefore = catalog.all.count

        let added = catalog.addCustom(name: "  Zercher Squat ", muscle: .legs)
        let again = catalog.addCustom(name: "zercher squat", muscle: .legs)
        let builtIn = catalog.addCustom(name: "bench press", muscle: .chest)

        #expect(added.name == "Zercher Squat")
        #expect(added.isCustom)
        #expect(again == added)
        #expect(!builtIn.isCustom)
        #expect(catalog.all.count == countBefore + 1)
        #expect(catalog.all.last == added)
        #expect(ExerciseCatalog(container: store.container).all.count == countBefore + 1)
    }

    /// Installs from before descriptions existed get them filled in for built-ins, while a
    /// custom exercise the user left blank stays blank.
    @Test func builtInsSavedWithoutADescriptionGetOneOnLaunch() {
        // Simulate an older install: built-ins were saved before `summary` existed.
        let context = store.container.mainContext
        context.insert(Exercise(name: "Bench Press", muscle: .chest))
        context.insert(Exercise(name: "My Press", muscle: .chest, isCustom: true))

        let catalog = ExerciseCatalog(container: store.container)

        let bench = try! #require(catalog.all.first { $0.name == "Bench Press" })
        let custom = try! #require(catalog.all.first { $0.name == "My Press" })
        #expect(bench.summary.hasPrefix("Lie on a flat bench"))
        #expect(custom.summary.isEmpty)
    }

    /// A description written when creating an exercise is kept, without stray spaces.
    @Test func customExercisesKeepTheirDescription() {
        let catalog = ExerciseCatalog(container: store.container)

        let added = catalog.addCustom(name: "Landmine Press", muscle: .shoulders, summary: "  Press one end of a bar up and forward.\n")

        #expect(added.summary == "Press one end of a bar up and forward.")
    }
}
