import Foundation
import FoundationModels

/// Turns a spoken sentence into `VoiceCommand`s. Behind a protocol so `VoiceLogger` and the
/// UI can be tested and previewed without the on-device language model.
protocol WorkoutParser: Sendable {
    /// Works out what the user asked for.
    ///
    /// - Parameters:
    ///   - transcript: What was said, e.g. "bench 100 for 8 twice".
    ///   - context: What the parser needs to know about the workout and the user.
    /// - Returns: The commands, in the order they were said; empty if nothing was understood.
    func parse(_ transcript: String, context: ParseContext) async throws -> [VoiceCommand]
}

/// The little a parser needs to know, copied off the main actor before parsing.
nonisolated struct ParseContext: Sendable {
    /// The exercise you're on, so "100 for 8" needs no name.
    let currentExercise: String?
    /// The user's unit, for weights said without one.
    let unit: WeightUnit
    /// Every exercise name in the catalog, for the model to choose real names from.
    let exerciseNames: [String]
}

/// The real parser: Apple's on-device Foundation Models.
///
/// The model returns the commands as one typed list (guided generation), so it can't loop
/// or ramble. It has one tool, `findExercise`, to look up real exercise names from the
/// catalog. An earlier version gave it one tool per action, and on a phone it kept calling
/// them and never finished. Nothing the model does changes data; `VoiceLogger` acts.
/// A fresh session per sentence keeps earlier sentences from leaking into the next one.
nonisolated struct FoundationModelsParser: WorkoutParser {
    /// Whether this device can run the model (Apple Intelligence on and ready).
    static var isAvailable: Bool {
        if case .available = SystemLanguageModel.default.availability {
            return true
        }
        return false
    }

    /// Asks the model for the commands in what was said.
    ///
    /// - Parameters:
    ///   - transcript: What was said.
    ///   - context: The current exercise, the user's unit and the catalog names.
    /// - Returns: The commands, in order; incomplete ones (a set with no reps) are dropped.
    func parse(_ transcript: String, context: ParseContext) async throws -> [VoiceCommand] {
        let session = LanguageModelSession(
            tools: [FindExerciseTool(names: context.exerciseNames)],
            instructions: Self.instructions(for: context)
        )
        // Low temperature: this is extraction, not writing, so the likeliest reading wins.
        let options = GenerationOptions(temperature: 0.1)
        let response = try await session.respond(to: transcript, generating: ParsedSentence.self, options: options)
        return response.content.commands.compactMap(\.command)
    }

    /// The model's standing instructions, including the current exercise and unit.
    ///
    /// - Parameter context: The workout context.
    /// - Returns: The instructions text.
    private static func instructions(for context: ParseContext) -> String {
        let current = context.currentExercise ?? "none yet"
        return """
        You turn what a lifter says at the gym into a list of commands.
        - logSets: "bench 100 for 8" is weight 100, reps 8. "twice" or "two sets" is count 2, otherwise count 1.
        - repeatLastSet: "same again", "one more", "another one".
        - editLastSet: "make that 6", "it was 105", "actually 7 reps".
        - addExercise: "add squats", with no numbers.
        - When an exercise is named, call findExercise once and use the best name it returns.
        - Leave exercise empty when none is named; it means the current exercise.
        - Leave weight empty when none is said; set unit only when they say kilos/kg or pounds/lb.
        Current exercise: \(current). The user's unit: \(context.unit.rawValue).
        """
    }
}

// MARK: - What the model fills in

/// Everything said in one sentence.
@Generable
nonisolated struct ParsedSentence {
    @Guide(description: "One command per thing the user asked for, in the order said. Usually just one.")
    var commands: [ParsedCommand]
}

/// One command as the model fills it in; converted to a `VoiceCommand`.
@Generable
nonisolated struct ParsedCommand {
    @Guide(description: "What to do")
    var action: ParsedAction
    @Guide(description: "Exercise name from findExercise; empty for the current exercise")
    var exercise: String?
    @Guide(description: "The weight number said; empty if none")
    var weight: Double?
    @Guide(description: "Only if the user said kilos or pounds")
    var unit: SpokenUnit?
    @Guide(description: "Repetitions; empty if none said")
    var reps: Int?
    @Guide(description: "How many sets or repeats; 1 unless they said twice, two more, etc.", .range(1...10))
    var count: Int

    /// The app's command for this, or nil when a needed part is missing.
    var command: VoiceCommand? {
        let unit = self.unit?.weightUnit
        switch action {
        case .logSets:
            guard let reps else {
                return nil
            }
            return .logSets(exercise: blankIsNil(exercise), weight: weight, unit: unit, reps: reps, count: count)
        case .repeatLastSet:
            return .repeatLast(count: count)
        case .editLastSet:
            if weight == nil && reps == nil {
                return nil
            }
            return .editLast(weight: weight, unit: unit, reps: reps)
        case .addExercise:
            guard let name = blankIsNil(exercise) else {
                return nil
            }
            return .addExercise(name: name)
        }
    }

    /// Treats an empty or all-space string like nil; the model sometimes writes "" for empty.
    ///
    /// - Parameter text: The string to check.
    /// - Returns: The string, or nil if it has no content.
    private func blankIsNil(_ text: String?) -> String? {
        guard let text, !text.trimmingCharacters(in: .whitespaces).isEmpty else {
            return nil
        }
        return text
    }
}

/// The kinds of command.
@Generable
nonisolated enum ParsedAction {
    case logSets
    case repeatLastSet
    case editLastSet
    case addExercise
}

/// A unit the user can say.
@Generable
nonisolated enum SpokenUnit {
    case kg
    case lb

    /// The app's unit for this spoken one.
    var weightUnit: WeightUnit {
        switch self {
        case .kg:
            return .kilograms
        case .lb:
            return .pounds
        }
    }
}

// MARK: - Tool

/// Looks up real exercise names, so the model never invents one.
private nonisolated struct FindExerciseTool: Tool {
    let name = "findExercise"
    let description = "Finds exercises whose name matches what the user said. Returns up to 5 exact names, best first."
    /// Every catalog name.
    let names: [String]

    @Generable
    nonisolated struct Arguments {
        @Guide(description: "The exercise as the user said it, e.g. 'bench' or 'lat pulldown'")
        var query: String
    }

    /// Returns names containing the most words of the query, plainest (shortest) first.
    ///
    /// - Parameter arguments: The query.
    /// - Returns: Up to 5 names, one per line, or a note that none matched.
    func call(arguments: Arguments) async throws -> String {
        let words = arguments.query.lowercased().split(separator: " ").map(String.init)
        var scored: [(name: String, score: Int)] = []
        for name in names {
            let lower = name.lowercased()
            let score = words.filter { lower.contains($0) }.count
            if score > 0 {
                scored.append((name, score))
            }
        }
        scored.sort { first, second in
            if first.score != second.score {
                return first.score > second.score
            }
            return first.name.count < second.name.count
        }
        let best = scored.prefix(5).map(\.name)
        if best.isEmpty {
            return "No exercise matches \"\(arguments.query)\"."
        }
        return best.joined(separator: "\n")
    }
}
