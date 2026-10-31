import Foundation
import Testing
@testable import yeahBuddy

/// True on a real device with the model ready. Outside the suite because the suite's own
/// attribute can't refer to a member of the suite.
private var modelCanRun: Bool {
    #if targetEnvironment(simulator)
    return false
    #else
    return FoundationModelsParser.isAvailable
    #endif
}

/// The real on-device parser against sample phrases. Runs only on a device with Apple
/// Intelligence: the simulator reports the model as available but has no model files, so
/// every call there fails at once.
///
/// The model isn't deterministic, so these check the shape of what comes back, and that it
/// comes back quickly: a parse that hangs leaves the user stuck on "Thinking…".
@MainActor
@Suite(.enabled(if: modelCanRun), .timeLimit(.minutes(1)))
struct FoundationModelsParserTests {
    /// The catalog names, as the app passes them.
    let names = BuiltInExercises.all.map(\.name)

    /// Parses a phrase, timing it.
    ///
    /// - Parameters:
    ///   - phrase: What was "said".
    ///   - current: The exercise being done, if any.
    /// - Returns: The commands and how long the parse took.
    func parse(_ phrase: String, current: String? = nil) async throws -> (commands: [VoiceCommand], seconds: Double) {
        let context = ParseContext(currentExercise: current, unit: .kilograms, exerciseNames: names)
        let start = ContinuousClock.now
        let commands = try await FoundationModelsParser().parse(phrase, context: context)
        let elapsed = ContinuousClock.now - start
        let seconds = Double(elapsed.components.seconds) + Double(elapsed.components.attoseconds) / 1e18
        print("PARSE \"\(phrase)\" -> \(commands) in \(seconds)s")
        return (commands, seconds)
    }

    /// A named exercise with weight, reps and a count.
    @Test func namedSetsTwice() async throws {
        let result = try await parse("bench 100 for 8 twice")

        #expect(result.commands.count == 1)
        if case .logSets(let exercise, let weight, _, let reps, let count) = result.commands.first {
            #expect(exercise?.localizedCaseInsensitiveContains("bench") == true)
            #expect(weight == 100)
            #expect(reps == 8)
            #expect(count == 2)
        } else {
            Issue.record("Expected logSets, got \(result.commands)")
        }
        #expect(result.seconds < 15)
    }

    /// "Same again" repeats.
    @Test func sameAgain() async throws {
        let result = try await parse("same again", current: "Squat")

        #expect(result.commands == [.repeatLast(count: 1)])
        #expect(result.seconds < 15)
    }

    /// "Make that 6 reps" edits.
    @Test func makeThatSix() async throws {
        let result = try await parse("make that 6 reps", current: "Squat")

        #expect(result.commands == [.editLast(weight: nil, unit: nil, reps: 6)])
        #expect(result.seconds < 15)
    }

    /// "Add lat pulldown" adds.
    @Test func addExercise() async throws {
        let result = try await parse("add lat pulldown")

        #expect(result.commands == [.addExercise(name: "Lat Pulldown")])
        #expect(result.seconds < 15)
    }

    /// Bare numbers go to the current exercise, with pounds noted.
    @Test func bareNumbersInPounds() async throws {
        let result = try await parse("135 pounds for 5", current: "Squat")

        #expect(result.commands == [.logSets(exercise: nil, weight: 135, unit: .pounds, reps: 5, count: 1)])
        #expect(result.seconds < 15)
    }
}
