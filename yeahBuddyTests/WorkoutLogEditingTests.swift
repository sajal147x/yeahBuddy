import Foundation
import Testing
@testable import yeahBuddy

/// Changing sets that are already logged in `WorkoutLog`. Kept apart from `WorkoutLogTests`
/// so neither file passes 300 lines.
@MainActor
struct WorkoutLogEditingTests {
    /// A fresh in-memory store for each test.
    let store = TestStore()
    /// The clock every log in a test shares, so times are predictable.
    let clock = TestClock()

    /// Opens a log over this test's store and clock. Calling it twice simulates a relaunch.
    ///
    /// - Returns: A new `WorkoutLog`.
    func makeLog() -> WorkoutLog {
        WorkoutLog(container: store.container, now: { [clock] in clock.now })
    }

    /// Correcting a set changes its weight and reps, keeps its place, and is saved.
    @Test func updatingASetChangesItInPlaceAndPersists() {
        let log = makeLog()
        let bench = Exercise(name: "Bench Press", muscle: .chest)
        log.logSet(weightKg: 80, reps: 8, of: bench)
        clock.advance(by: 120)
        log.logSet(weightKg: 80, reps: 8, of: bench)
        let first = try! #require(log.active?.orderedEntries.first?.orderedSets.first)

        log.update(first, weightKg: 82.5, reps: 6)

        let sets = try! #require(makeLog().active?.orderedEntries.first?.orderedSets)
        #expect(sets.map(\.weightKg) == [82.5, 80])
        #expect(sets.map(\.reps) == [6, 8])
    }

    /// Last time's whole session for an exercise, in order, so a new card can lay it out to
    /// repeat. Skips a later workout where the exercise was added but nothing logged, and
    /// ignores the workout in progress.
    @Test func lastSetsAreTheWholeLastSessionInOrder() {
        let log = makeLog()
        let bench = Exercise(name: "Bench Press", muscle: .chest)
        // An older session, then the one that should win.
        log.logSet(weightKg: 60, reps: 10, of: bench)
        log.finish()
        clock.advance(by: 3600)
        log.logSet(weightKg: 80, reps: 8, of: bench)
        clock.advance(by: 120)
        log.logSet(weightKg: 82.5, reps: 6, of: bench)
        log.finish()
        // A later session where bench was added but skipped.
        clock.advance(by: 3600)
        log.add(bench)
        log.logSet(weightKg: 100, reps: 5, of: Exercise(name: "Squat", muscle: .legs))
        log.finish()
        // Today's workout, in progress, with one set already.
        clock.advance(by: 3600)
        log.logSet(weightKg: 90, reps: 3, of: bench)

        let last = log.lastSets(of: bench)

        #expect(last.map(\.weightKg) == [80, 82.5])
        #expect(last.map(\.reps) == [8, 6])
        #expect(log.lastSets(of: Exercise(name: "Deadlift", muscle: .back)).isEmpty)
    }
}
