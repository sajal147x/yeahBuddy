import Foundation
import Testing
@testable import yeahBuddy

/// What the Live Activity shows for a given workout and rest state. Only the content is
/// tested here; starting and updating the activity needs a device and is checked by hand.
@MainActor
struct WorkoutActivityTests {
    /// A fresh in-memory store for each test.
    let store = TestStore()
    /// The clock the log and rest timer share.
    let clock = TestClock()

    /// Opens a log over this test's store and clock.
    ///
    /// - Returns: A new `WorkoutLog`.
    func makeLog() -> WorkoutLog {
        WorkoutLog(container: store.container, now: { [clock] in clock.now })
    }

    /// Creates a stopped rest timer on this test's clock.
    ///
    /// - Returns: A new `RestTimer`.
    func makeTimer() -> RestTimer {
        RestTimer(now: { [clock] in clock.now })
    }

    /// No workout in progress means nothing to show, so the activity ends.
    @Test func noContentWithoutAWorkoutInProgress() {
        #expect(WorkoutActivity.content(log: makeLog(), rest: makeTimer(), unit: .kilograms) == nil)
    }

    /// Mid-workout while resting: the current exercise, the next set number, the last set in
    /// the user's unit, and the rest's end and full length.
    @Test func showsTheCurrentExerciseLastSetAndRest() throws {
        let log = makeLog()
        let rest = makeTimer()
        let bench = Exercise(name: "Bench Press", muscle: .chest)
        log.logSet(weightKg: 60, reps: 8, of: bench)
        // Sets are ordered by time, so give the second one a later time.
        clock.advance(by: 120)
        log.logSet(weightKg: WeightUnit.pounds.kilograms(from: 135), reps: 8, of: bench)
        rest.start(seconds: 90)
        rest.extend(by: 15)

        let content = try #require(WorkoutActivity.content(log: log, rest: rest, unit: .pounds))

        #expect(content.title == "Chest")
        #expect(content.exerciseName == "Bench Press")
        #expect(content.nextSetNumber == 3)
        #expect(content.lastSet == "135 lb × 8")
        #expect(content.restEndsAt == clock.now.addingTimeInterval(105))
        #expect(content.restTotal == 105)
    }

    /// Just added an exercise and not resting: set 1, no last set, no countdown.
    @Test func aFreshExerciseStartsAtSetOneWithNoRest() throws {
        let log = makeLog()
        log.add(Exercise(name: "Squat", muscle: .legs))

        let content = try #require(WorkoutActivity.content(log: log, rest: makeTimer(), unit: .kilograms))

        #expect(content.exerciseName == "Squat")
        #expect(content.nextSetNumber == 1)
        #expect(content.lastSet == nil)
        #expect(content.restEndsAt == nil)
    }
}
