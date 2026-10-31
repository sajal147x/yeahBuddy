import Foundation
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
        // Sorted the way people read names, ignoring case ("EZ Bar Curl" before "External").
        let names = first.all.map(\.name)
        #expect(names == names.sorted { $0.localizedStandardCompare($1) == .orderedAscending })
    }

    /// An install made before newer built-ins existed gets them on its next launch, without
    /// duplicating one the user already created under the same name (in any case).
    @Test func newBuiltInsReachExistingInstallsWithoutDuplicates() {
        // Simulate an older install: one built-in from back then, plus a custom exercise
        // whose name matches a built-in added later.
        let context = store.container.mainContext
        context.insert(Exercise(name: "Bench Press", muscle: .chest))
        context.insert(Exercise(name: "deadlift", muscle: .back, isCustom: true))

        let catalog = ExerciseCatalog(container: store.container)
        let relaunched = ExerciseCatalog(container: store.container)

        // Every built-in is there except Deadlift, which the custom one stands in for.
        #expect(catalog.all.count == BuiltInExercises.all.count)
        #expect(catalog.all.filter { $0.name.lowercased() == "deadlift" }.count == 1)
        #expect(catalog.all.contains { $0.name == "Squat" && !$0.isCustom })
        #expect(relaunched.all.count == catalog.all.count)
    }

    /// Search finds partial, any-case matches; blank search shows everything.
    @Test func searchMatchesAnyPartOfTheNameIgnoringCase() {
        let catalog = ExerciseCatalog(container: store.container)

        let curls = catalog.search("CURL")
        // Every match contains "curl" and every exercise containing it is found, so the test
        // doesn't need updating whenever a curl is added to the built-ins.
        #expect(curls.allSatisfy { $0.name.lowercased().contains("curl") })
        #expect(curls.count == catalog.all.filter { $0.name.lowercased().contains("curl") }.count)
        #expect(curls.contains { $0.name == "Barbell Curl" })
        #expect(curls.contains { $0.name == "Leg Curl" })
        #expect(catalog.search("  ").count == catalog.all.count)
    }

    /// No two built-ins share a name in any case, since names are how stored exercises are
    /// matched back to the list; a duplicate would silently never be added.
    @Test func builtInNamesAreUnique() {
        let names = BuiltInExercises.all.map { $0.name.lowercased() }

        #expect(Set(names).count == names.count)
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
        #expect(catalog.all.contains(added))
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

        let added = catalog.addCustom(name: "Viking Press", muscle: .shoulders, summary: "  Press one end of a bar up and forward.\n")

        #expect(added.summary == "Press one end of a bar up and forward.")
    }
}
