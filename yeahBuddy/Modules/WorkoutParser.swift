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

/// The real parser: Apple's on-device Foundation Models with tool calling.
///
/// The model is given one tool per command plus a lookup tool for exercise names. Its tool
/// calls are collected as commands; nothing it does changes data. A fresh session per
/// sentence keeps earlier sentences from leaking into the next one.
nonisolated struct FoundationModelsParser: WorkoutParser {
    /// Whether this device can run the model (Apple Intelligence on and ready).
    static var isAvailable: Bool {
        if case .available = SystemLanguageModel.default.availability {
            return true
        }
        return false
    }

    /// Asks the model to call the tools for what was said, then returns those calls.
    ///
    /// - Parameters:
    ///   - transcript: What was said.
    ///   - context: The current exercise, the user's unit and the catalog names.
    /// - Returns: The commands the model called, in order.
    func parse(_ transcript: String, context: ParseContext) async throws -> [VoiceCommand] {
        let collector = CommandCollector()
        let tools: [any Tool] = [
            FindExerciseTool(names: context.exerciseNames),
            AddExerciseTool(collector: collector),
            LogSetsTool(collector: collector),
            RepeatLastSetTool(collector: collector),
            EditLastSetTool(collector: collector),
        ]
        let session = LanguageModelSession(tools: tools, instructions: Self.instructions(for: context))
        _ = try await session.respond(to: transcript)
        return await collector.commands
    }

    /// The model's standing instructions, including the current exercise and unit.
    ///
    /// - Parameter context: The workout context.
    /// - Returns: The instructions text.
    private static func instructions(for context: ParseContext) -> String {
        let current = context.currentExercise ?? "none yet"
        return """
        You log gym sets from what the user says. Call tools only; never answer in prose.
        - Before naming an exercise in a tool, call findExercise and use a name it returns exactly.
        - "bench 100 for 8" means logSets with weight 100 and reps 8. "twice" or "two sets" means count 2.
        - With no exercise named, leave exercise empty: it means the current exercise.
        - With no weight said, leave weight empty: it means the same weight as last time.
        - "same again" or "one more" means repeatLastSet. "make that 6" or "it was 105" means editLastSet.
        - "add squats" (no numbers) means addExercise.
        - Only set unit when the user says kilos/kg or pounds/lb.
        Current exercise: \(current). The user's unit: \(context.unit.rawValue).
        """
    }
}

// MARK: - Tools

/// Gathers the commands the model calls. An actor because tool calls may run concurrently.
private actor CommandCollector {
    /// The commands so far, in call order.
    private(set) var commands: [VoiceCommand] = []

    /// Adds one command.
    ///
    /// - Parameter command: The command the model called.
    func add(_ command: VoiceCommand) {
        commands.append(command)
    }
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

/// Looks up real exercise names, so the model never invents one.
private nonisolated struct FindExerciseTool: Tool {
    let name = "findExercise"
    let description = "Finds exercises whose name matches what the user said. Returns up to 5 exact names."
    /// Every catalog name.
    let names: [String]

    @Generable
    nonisolated struct Arguments {
        @Guide(description: "A word or two from the exercise the user said, e.g. 'bench' or 'pulldown'")
        var query: String
    }

    /// Returns names containing any word of the query, best (most words matched) first.
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
        scored.sort { $0.score > $1.score }
        let best = scored.prefix(5).map(\.name)
        if best.isEmpty {
            return "No exercise matches \"\(arguments.query)\"."
        }
        return best.joined(separator: "\n")
    }
}

/// "Add lat pulldown".
private nonisolated struct AddExerciseTool: Tool {
    let name = "addExercise"
    let description = "Adds an exercise to the workout without logging a set."
    let collector: CommandCollector

    @Generable
    nonisolated struct Arguments {
        @Guide(description: "The exact exercise name from findExercise")
        var exercise: String
    }

    /// Records the command.
    ///
    /// - Parameter arguments: The exercise.
    /// - Returns: A confirmation for the model.
    func call(arguments: Arguments) async throws -> String {
        await collector.add(.addExercise(name: arguments.exercise))
        return "Done."
    }
}

/// "Bench 100 for 8, twice".
private nonisolated struct LogSetsTool: Tool {
    let name = "logSets"
    let description = "Logs one or more identical sets."
    let collector: CommandCollector

    @Generable
    nonisolated struct Arguments {
        @Guide(description: "Exact name from findExercise; omit for the current exercise")
        var exercise: String?
        @Guide(description: "The weight number said; omit if none was said")
        var weight: Double?
        @Guide(description: "Only if the user said kilos or pounds")
        var unit: SpokenUnit?
        @Guide(description: "Repetitions per set", .range(1...100))
        var reps: Int
        @Guide(description: "How many sets; 1 unless they said twice, three sets, etc.", .range(1...10))
        var count: Int
    }

    /// Records the command.
    ///
    /// - Parameter arguments: The set details.
    /// - Returns: A confirmation for the model.
    func call(arguments: Arguments) async throws -> String {
        await collector.add(.logSets(
            exercise: arguments.exercise,
            weight: arguments.weight,
            unit: arguments.unit?.weightUnit,
            reps: arguments.reps,
            count: arguments.count
        ))
        return "Done."
    }
}

/// "Same again", "two more".
private nonisolated struct RepeatLastSetTool: Tool {
    let name = "repeatLastSet"
    let description = "Logs the most recent set again."
    let collector: CommandCollector

    @Generable
    nonisolated struct Arguments {
        @Guide(description: "How many times; 1 unless they said 'two more' etc.", .range(1...10))
        var count: Int
    }

    /// Records the command.
    ///
    /// - Parameter arguments: The count.
    /// - Returns: A confirmation for the model.
    func call(arguments: Arguments) async throws -> String {
        await collector.add(.repeatLast(count: arguments.count))
        return "Done."
    }
}

/// "Make that 6 reps", "it was 105".
private nonisolated struct EditLastSetTool: Tool {
    let name = "editLastSet"
    let description = "Corrects the weight or reps of the most recent set."
    let collector: CommandCollector

    @Generable
    nonisolated struct Arguments {
        @Guide(description: "The corrected weight; omit if unchanged")
        var weight: Double?
        @Guide(description: "Only if the user said kilos or pounds")
        var unit: SpokenUnit?
        @Guide(description: "The corrected reps; omit if unchanged")
        var reps: Int?
    }

    /// Records the command.
    ///
    /// - Parameter arguments: What changed.
    /// - Returns: A confirmation for the model.
    func call(arguments: Arguments) async throws -> String {
        await collector.add(.editLast(weight: arguments.weight, unit: arguments.unit?.weightUnit, reps: arguments.reps))
        return "Done."
    }
}
