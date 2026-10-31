import Foundation
import Testing
@testable import yeahBuddy

/// Behavior of `VoiceLogger`: turning parsed voice commands into logged sets, with undo.
/// Uses the real catalog and log over an in-memory store; no speech or language model.
@MainActor
struct VoiceLoggerTests {
    /// A fresh in-memory store for each test.
    let store = TestStore()
    /// The clock the log uses, so set order is predictable.
    let clock = TestClock()
    /// The workout log under the voice logger.
    let log: WorkoutLog
    /// The exercise catalog, seeded with the built-ins.
    let catalog: ExerciseCatalog
    /// The module under test.
    let voice: VoiceLogger

    /// Builds the log, catalog and voice logger over this test's store.
    init() {
        log = WorkoutLog(container: store.container, now: { [clock] in clock.now })
        catalog = ExerciseCatalog(container: store.container)
        voice = VoiceLogger(log: log, catalog: catalog)
    }

    /// The catalog exercise with this exact name; the test fails if it's missing.
    ///
    /// - Parameter name: A built-in exercise name.
    /// - Returns: The exercise.
    func exercise(_ name: String) -> Exercise {
        try! #require(catalog.all.first { $0.name == name })
    }

    /// Every set in the workout in progress as (exercise, kg, reps), in order.
    var loggedSets: [String] {
        let entries = log.active?.orderedEntries ?? []
        return entries.flatMap { entry in
            entry.orderedSets.map { "\(entry.exercise?.name ?? "?") \($0.weightKg)×\($0.reps)" }
        }
    }

    /// Applies commands, failing the test if the logger refused them.
    ///
    /// - Parameters:
    ///   - commands: What was "said".
    ///   - unit: The user's unit.
    /// - Returns: The summary and the change, for undo.
    @discardableResult
    func applied(_ commands: [VoiceCommand], unit: WeightUnit = .kilograms) -> (summary: String, change: VoiceChange) {
        switch voice.apply(commands, unit: unit) {
        case .applied(let summary, let change):
            return (summary, change)
        case .failed(let message):
            Issue.record("Expected success, got: \(message)")
            return ("", VoiceChange())
        }
    }

    /// "Bench 100 for 8, twice" adds Bench Press to the workout and logs two sets.
    @Test func logsSetsAddingTheExerciseWhenNeeded() {
        log.start()

        let result = applied([.logSets(exercise: "bench press", weight: 100, unit: nil, reps: 8, count: 2)])

        #expect(loggedSets == ["Bench Press 100.0×8", "Bench Press 100.0×8"])
        #expect(result.summary == "Logged 2 × Bench Press 100 kg × 8")
    }

    /// A name that isn't exact still works when it matches exactly one exercise.
    @Test func aPartialNameWithOneMatchIsUsed() {
        applied([.logSets(exercise: "pendlay", weight: 60, unit: nil, reps: 5, count: 1)])

        #expect(loggedSets == ["Pendlay Row 60.0×5"])
    }

    /// No exercise named means the one you're on, and no weight means its last weight.
    @Test func bareRepsGoToTheCurrentExerciseAtItsLastWeight() {
        log.logSet(weightKg: 80, reps: 8, of: exercise("Squat"))
        clock.advance(by: 120)

        applied([.logSets(exercise: nil, weight: nil, unit: nil, reps: 6, count: 1)])

        #expect(loggedSets == ["Squat 80.0×8", "Squat 80.0×6"])
    }

    /// Spoken pounds are stored as kilograms, and the summary uses the user's unit.
    @Test func poundsAreConvertedToKilograms() {
        let result = applied(
            [.logSets(exercise: "Deadlift", weight: 225, unit: .pounds, reps: 5, count: 1)],
            unit: .pounds
        )

        let set = try! #require(log.active?.orderedEntries.first?.orderedSets.first)
        #expect(abs(set.weightKg - WeightUnit.pounds.kilograms(from: 225)) < 0.0001)
        #expect(result.summary == "Logged Deadlift 225 lb × 5")
    }

    /// "Same again" logs the latest set once more.
    @Test func repeatLastLogsTheLatestSetAgain() {
        log.logSet(weightKg: 100, reps: 5, of: exercise("Squat"))
        clock.advance(by: 120)

        let result = applied([.repeatLast(count: 2)])

        #expect(loggedSets == ["Squat 100.0×5", "Squat 100.0×5", "Squat 100.0×5"])
        #expect(result.summary == "Logged 2 × Squat 100 kg × 5")
    }

    /// "Make that 6" changes only the reps of the latest set.
    @Test func editLastChangesOnlyWhatWasSaid() {
        log.logSet(weightKg: 100, reps: 5, of: exercise("Squat"))
        clock.advance(by: 120)
        log.logSet(weightKg: 100, reps: 5, of: exercise("Squat"))

        let result = applied([.editLast(weight: nil, unit: nil, reps: 6)])

        #expect(loggedSets == ["Squat 100.0×5", "Squat 100.0×6"])
        #expect(result.summary == "Changed to Squat 100 kg × 6")
    }

    /// "Add lat pulldown" adds the exercise without logging anything.
    @Test func addExerciseAddsWithoutLogging() {
        let result = applied([.addExercise(name: "Lat Pulldown")])

        #expect(log.active?.orderedEntries.map(\.exercise?.name) == ["Lat Pulldown"])
        #expect(loggedSets.isEmpty)
        #expect(result.summary == "Added Lat Pulldown")
    }

    /// An unknown exercise logs nothing at all, even if an earlier command was fine.
    @Test func anUnknownExerciseChangesNothing() {
        log.logSet(weightKg: 100, reps: 5, of: exercise("Squat"))

        let outcome = voice.apply([
            .repeatLast(count: 1),
            .logSets(exercise: "benchy wobble", weight: 50, unit: nil, reps: 5, count: 1),
        ], unit: .kilograms)

        #expect(outcome == .failed("Couldn't find “benchy wobble”"))
        #expect(loggedSets == ["Squat 100.0×5"])
    }

    /// Nothing to repeat or edit, or no weight to reuse, is refused with a helpful message.
    @Test func missingContextIsRefused() {
        log.start()

        #expect(voice.apply([.repeatLast(count: 1)], unit: .kilograms) == .failed("No set to repeat yet"))
        #expect(voice.apply([.editLast(weight: nil, unit: nil, reps: 6)], unit: .kilograms) == .failed("No set to change yet"))
        #expect(voice.apply([.logSets(exercise: nil, weight: 50, unit: nil, reps: 5, count: 1)], unit: .kilograms) == .failed("Say which exercise"))
        #expect(voice.apply([.logSets(exercise: "Squat", weight: nil, unit: nil, reps: 5, count: 1)], unit: .kilograms) == .failed("Say the weight"))
        #expect(voice.apply([], unit: .kilograms) == .failed("Didn't catch that"))
        #expect(loggedSets.isEmpty)
    }

    /// Undo puts the workout back exactly as it was: new sets and exercises go, edits revert.
    @Test func undoRestoresThePreviousState() {
        log.logSet(weightKg: 100, reps: 5, of: exercise("Squat"))
        clock.advance(by: 120)
        let before = loggedSets

        let result = applied([
            .editLast(weight: 110, unit: nil, reps: nil),
            .logSets(exercise: "Bench Press", weight: 80, unit: nil, reps: 8, count: 2),
        ])
        voice.undo(result.change)

        #expect(loggedSets == before)
        #expect(log.active?.orderedEntries.map(\.exercise?.name) == ["Squat"])
    }
}
