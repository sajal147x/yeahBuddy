import Foundation
import SwiftData
import Testing
@testable import yeahBuddy

@MainActor
struct WorkoutLogTests {
    let store = TestStore()
    let clock = TestClock()

    func makeLog() -> WorkoutLog {
        WorkoutLog(container: store.container, now: { [clock] in clock.now })
    }

    @Test func worksWhenTheCallerDoesNotHoldTheStore() {
        let log = WorkoutLog(container: try! ModelContainer(
            for: AppSchema.schema,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        ))

        log.start()

        #expect(log.active != nil)
    }

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

    @Test func finishingAWorkoutWithNoSetsDiscardsIt() {
        let log = makeLog()
        log.add(Exercise(name: "Bench Press", muscle: .chest))

        log.finish()

        #expect(log.active == nil)
        #expect(log.history.isEmpty)
        #expect(makeLog().history.isEmpty)
    }

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

    @Test func removingAnExerciseKeepsTheOthersInOrder() {
        let log = makeLog()
        log.add(Exercise(name: "Bench Press", muscle: .chest))
        let mistake = log.add(Exercise(name: "Leg Curl", muscle: .legs))
        log.add(Exercise(name: "Squat", muscle: .legs))

        log.remove(mistake)

        let names = try! #require(log.active).orderedEntries.map(\.exercise?.name)
        #expect(names == ["Bench Press", "Squat"])
    }
}
