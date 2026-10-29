import Testing
@testable import yeahBuddy

/// The summary numbers a workout tile shows.
@MainActor
struct WorkoutSummaryTests {
    /// A fresh in-memory store for each test.
    let store = TestStore()
    /// The clock the log uses, so set times are predictable.
    let clock = TestClock()

    /// Volume and set count add up across every exercise in the workout.
    @Test func totalsVolumeAndSetsAcrossExercises() {
        let log = WorkoutLog(container: store.container, now: { [clock] in clock.now })
        let bench = Exercise(name: "Bench Press", muscle: .chest)
        let squat = Exercise(name: "Squat", muscle: .legs)
        log.logSet(weightKg: 80, reps: 8, of: bench)
        clock.advance(by: 60)
        log.logSet(weightKg: 85, reps: 6, of: bench)
        clock.advance(by: 60)
        log.logSet(weightKg: 100, reps: 5, of: squat)

        let workout = try! #require(log.active)

        // 80×8 + 85×6 + 100×5
        #expect(workout.totalVolumeKg == 1650)
        #expect(workout.setCount == 3)
    }
}
