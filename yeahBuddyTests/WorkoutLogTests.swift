import Foundation
import SwiftData
import Testing
@testable import yeahBuddy

/// Behavior of `WorkoutLog`, tested only through its public interface.
@MainActor
struct WorkoutLogTests {
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

    /// Regression: the app crashed when only the log, not the caller, held the store.
    @Test func worksWhenTheCallerDoesNotHoldTheStore() {
        let log = WorkoutLog(container: try! ModelContainer(
            for: AppSchema.schema,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        ))

        log.start()

        #expect(log.active != nil)
    }

    /// Logging is possible straight away: no need to start a workout or add the exercise first.
    @Test func loggingASetWithNoWorkoutRunningStartsOne() {
        let log = makeLog()
        let bench = Exercise(name: "Bench Press", muscle: .chest)

        log.logSet(weightKg: 80, reps: 8, of: bench)

        let workout = try! #require(log.active)
        #expect(workout.startedAt == clock.now)
        #expect(workout.orderedEntries.map(\.exercise?.name) == ["Bench Press"])
        #expect(workout.orderedEntries[0].orderedSets.map(\.reps) == [8])
        #expect(workout.orderedEntries[0].orderedSets.map(\.weightKg) == [80])
    }

    /// Sets of the same exercise group together even when other exercises come in between.
    @Test func setsJoinTheRunningWorkoutGroupedByExerciseInOrder() {
        let log = makeLog()
        let bench = Exercise(name: "Bench Press", muscle: .chest)
        let squat = Exercise(name: "Squat", muscle: .legs)

        log.logSet(weightKg: 80, reps: 8, of: bench)
        clock.advance(by: 120)
        log.logSet(weightKg: 100, reps: 5, of: squat)
        clock.advance(by: 120)
        log.logSet(weightKg: 85, reps: 6, of: bench)

        let entries = try! #require(log.active).orderedEntries
        #expect(entries.map(\.exercise?.name) == ["Bench Press", "Squat"])
        #expect(entries[0].orderedSets.map(\.reps) == [8, 6])
        #expect(entries[1].orderedSets.map(\.reps) == [5])
    }

    /// Finishing stamps the end time and moves the workout to the top of history.
    @Test func finishedWorkoutsAppearInHistoryNewestFirst() {
        let log = makeLog()
        let bench = Exercise(name: "Bench Press", muscle: .chest)

        log.logSet(weightKg: 80, reps: 8, of: bench)
        let first = try! #require(log.active)
        clock.advance(by: 3600)
        log.finish()
        clock.advance(by: 86_400)
        log.logSet(weightKg: 82.5, reps: 8, of: bench)
        let second = try! #require(log.active)
        log.finish()

        #expect(log.active == nil)
        #expect(log.history == [second, first])
        #expect(first.endedAt == first.startedAt.addingTimeInterval(3600))
    }

    /// Closing the app mid-workout loses nothing: a new log picks up where the old one left off.
    @Test func aRelaunchedLogResumesTheWorkoutInProgressAndHistory() {
        let bench = Exercise(name: "Bench Press", muscle: .chest)
        let before = makeLog()
        before.logSet(weightKg: 80, reps: 8, of: bench)
        let finished = try! #require(before.active)
        before.finish()
        clock.advance(by: 86_400)
        before.logSet(weightKg: 82.5, reps: 8, of: bench)
        let inProgress = try! #require(before.active)

        let after = makeLog()

        #expect(after.active == inProgress)
        #expect(after.history == [finished])
    }

    /// A workout with no sets is thrown away rather than cluttering history.
    @Test func finishingAWorkoutWithNoSetsDiscardsIt() {
        let log = makeLog()
        log.add(Exercise(name: "Bench Press", muscle: .chest))

        log.finish()

        #expect(log.active == nil)
        #expect(log.history.isEmpty)
        #expect(makeLog().history.isEmpty)
    }

    /// A mistyped set (800 kg) can be removed without touching the others.
    @Test func removingASetTakesItOutOfItsExercise() {
        let log = makeLog()
        let bench = Exercise(name: "Bench Press", muscle: .chest)
        log.logSet(weightKg: 80, reps: 8, of: bench)
        clock.advance(by: 90)
        log.logSet(weightKg: 800, reps: 6, of: bench)
        let entry = try! #require(log.active).orderedEntries[0]

        log.remove(entry.orderedSets[1])

        #expect(entry.orderedSets.map(\.weightKg) == [80])
    }

    /// Delete works the same for a finished workout and the one in progress, and sticks.
    @Test func deletingAWorkoutRemovesItWhetherFinishedOrInProgress() {
        let log = makeLog()
        let bench = Exercise(name: "Bench Press", muscle: .chest)
        log.logSet(weightKg: 80, reps: 8, of: bench)
        let finished = try! #require(log.active)
        log.finish()
        log.logSet(weightKg: 80, reps: 8, of: bench)
        let inProgress = try! #require(log.active)

        log.delete(finished)
        log.delete(inProgress)

        #expect(log.active == nil)
        #expect(log.history.isEmpty)
        let relaunched = makeLog()
        #expect(relaunched.active == nil)
        #expect(relaunched.history.isEmpty)
    }

    /// Removing an exercise from the middle doesn't shuffle the rest.
    @Test func removingAnExerciseKeepsTheOthersInOrder() {
        let log = makeLog()
        log.add(Exercise(name: "Bench Press", muscle: .chest))
        let mistake = log.add(Exercise(name: "Leg Curl", muscle: .legs))
        log.add(Exercise(name: "Squat", muscle: .legs))

        log.remove(mistake)

        let names = try! #require(log.active).orderedEntries.map(\.exercise?.name)
        #expect(names == ["Bench Press", "Squat"])
    }

    /// A new exercise card starts from where you left off: the final set of the most recent
    /// finished workout that has the exercise, not an older one.
    @Test func lastSetIsTheFinalSetOfTheNewestFinishedWorkout() {
        let log = makeLog()
        let bench = Exercise(name: "Bench Press", muscle: .chest)
        log.logSet(weightKg: 80, reps: 8, of: bench)
        log.finish()
        clock.advance(by: 86_400)
        log.logSet(weightKg: 100, reps: 5, of: bench)
        log.logSet(weightKg: 90, reps: 8, of: bench)
        log.finish()

        let last = try! #require(log.lastSet(of: bench))

        #expect(last.weightKg == 90)
        #expect(last.reps == 8)
    }

    /// An exercise never done before has no last set, so its card falls back to the empty bar.
    @Test func lastSetIsNilForAnExerciseNeverDone() {
        let log = makeLog()
        log.logSet(weightKg: 100, reps: 5, of: Exercise(name: "Squat", muscle: .legs))
        log.finish()

        #expect(log.lastSet(of: Exercise(name: "Bench Press", muscle: .chest)) == nil)
    }

    /// A workout where the exercise was added but never logged doesn't hide the one before it.
    @Test func lastSetSkipsAWorkoutWhereTheExerciseHadNoSets() {
        let log = makeLog()
        let bench = Exercise(name: "Bench Press", muscle: .chest)
        log.logSet(weightKg: 80, reps: 8, of: bench)
        log.finish()
        clock.advance(by: 86_400)
        log.add(bench)
        log.logSet(weightKg: 100, reps: 5, of: Exercise(name: "Squat", muscle: .legs))
        log.finish()

        #expect(log.lastSet(of: bench)?.weightKg == 80)
    }

    /// The workout in progress doesn't count: its card already shows its own sets.
    @Test func lastSetIgnoresTheWorkoutInProgress() {
        let log = makeLog()
        let bench = Exercise(name: "Bench Press", muscle: .chest)
        log.logSet(weightKg: 80, reps: 8, of: bench)
        log.finish()
        clock.advance(by: 86_400)
        log.logSet(weightKg: 100, reps: 5, of: bench)

        #expect(log.lastSet(of: bench)?.weightKg == 80)
    }

    /// This Week counts only finished workouts started since the start of the current week
    /// (Monday here), so last week's session and the one still in progress are left out.
    @Test func thisWeekTotalsFinishedWorkoutsSinceTheWeekStarted() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.firstWeekday = 2
        let log = WorkoutLog(container: store.container, now: { [clock] in clock.now }, calendar: calendar)
        let bench = Exercise(name: "Bench Press", muscle: .chest)
        let day: TimeInterval = 86_400
        // The test clock starts on Monday 1 Jan 2001, 00:00 UTC.
        let monday = clock.now

        clock.now = monday.addingTimeInterval(-2 * day)  // Saturday last week
        log.logSet(weightKg: 60, reps: 10, of: bench)
        log.finish()
        clock.now = monday.addingTimeInterval(1 * day)  // Tuesday
        log.logSet(weightKg: 80, reps: 8, of: bench)
        log.logSet(weightKg: 80, reps: 8, of: bench)
        log.finish()
        clock.now = monday.addingTimeInterval(2 * day)  // Wednesday
        log.logSet(weightKg: 100, reps: 5, of: bench)
        log.finish()
        log.logSet(weightKg: 100, reps: 5, of: bench)  // still in progress

        let week = log.thisWeek()

        #expect(week.workouts == 2)
        #expect(week.sets == 3)
        // 80×8 + 80×8 + 100×5
        #expect(week.volumeKg == 1780)
    }
}
