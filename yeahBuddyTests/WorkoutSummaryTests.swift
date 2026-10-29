import Testing
@testable import yeahBuddy

@MainActor
struct WorkoutSummaryTests {
    let store = TestStore()
    let clock = TestClock()

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
