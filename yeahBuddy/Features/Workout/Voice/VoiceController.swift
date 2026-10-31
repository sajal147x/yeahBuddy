import Foundation
import Observation

/// Runs one voice action from tap to banner: listen, parse, apply, then offer Undo.
///
/// The workout screen owns one and draws `phase`; the work itself is done by
/// `SpeechListener`, a `WorkoutParser` and `VoiceLogger`.
@Observable
final class VoiceController {
    /// Where the current voice action is.
    enum Phase {
        /// Waiting for a tap on the mic.
        case idle
        /// Recording; the live transcript is on `listener`.
        case listening
        /// Speech is done; the language model is working out what was meant.
        case thinking
        /// Something was logged. `change` is what Undo takes back.
        case done(summary: String, change: VoiceChange)
        /// Nothing was logged, with the reason to show.
        case failed(String)
    }

    /// Where the current voice action is.
    private(set) var phase: Phase = .idle
    /// The microphone side, exposed for its live transcript.
    let listener = SpeechListener()

    private let parser: any WorkoutParser
    // The action in flight, so a cancel can stop it.
    private var work: Task<Void, Never>?

    /// Creates a controller with a parser.
    ///
    /// - Parameter parser: Turns sentences into commands; the real one by default.
    init(parser: any WorkoutParser = FoundationModelsParser()) {
        self.parser = parser
    }

    /// Whether voice logging can work on this device, so the mic is only shown when it can.
    static var isAvailable: Bool {
        FoundationModelsParser.isAvailable
    }

    /// Starts listening, then parses and applies what was said.
    ///
    /// - Parameters:
    ///   - logger: Applies the commands to the workout.
    ///   - context: The current exercise, unit and catalog names for the parser.
    ///   - unit: The user's unit, for the summary and unit-less weights.
    ///   - onLogged: Called after sets were logged (not for edits or adds), to start rest.
    func start(logger: VoiceLogger, context: ParseContext, unit: WeightUnit, onLogged: @escaping () -> Void) {
        work?.cancel()
        phase = .listening
        work = Task {
            do {
                let sentence = try await listener.listen()
                if Task.isCancelled {
                    return
                }
                if sentence.isEmpty {
                    phase = .idle
                    return
                }
                phase = .thinking
                let commands = try await Self.parse(sentence, with: parser, context: context)
                switch logger.apply(commands, unit: unit) {
                case .applied(let summary, let change):
                    phase = .done(summary: summary, change: change)
                    if !change.addedSets.isEmpty {
                        onLogged()
                    }
                case .failed(let message):
                    phase = .failed(message)
                }
            } catch is TimedOut {
                phase = .failed("That took too long. Try again")
            } catch SpeechListener.Failure.microphoneDenied {
                phase = .failed("Allow the microphone in Settings to log by voice")
            } catch SpeechListener.Failure.unsupportedLanguage {
                phase = .failed("Voice logging doesn't support this language yet")
            } catch {
                phase = .failed("Couldn't understand that. Try again")
            }
        }
    }

    // The longest "Thinking…" may last. A normal parse takes a second or two; past this,
    // something is stuck and the user is better off trying again.
    private static let parseTimeout: Duration = .seconds(20)

    /// Thrown when the parser runs past `parseTimeout`.
    private struct TimedOut: Error {}

    /// Runs the parser, giving up after `parseTimeout` so the screen can never sit on
    /// "Thinking…" indefinitely.
    ///
    /// - Parameters:
    ///   - sentence: What was said.
    ///   - parser: The parser.
    ///   - context: The parse context.
    /// - Returns: The parsed commands.
    /// - Throws: `TimedOut` past the limit, or whatever the parser throws.
    private static func parse(_ sentence: String, with parser: any WorkoutParser, context: ParseContext) async throws -> [VoiceCommand] {
        try await withThrowingTaskGroup(of: [VoiceCommand].self) { group in
            group.addTask {
                try await parser.parse(sentence, context: context)
            }
            group.addTask {
                try await Task.sleep(for: parseTimeout)
                throw TimedOut()
            }
            // Whichever finishes first wins; the other is cancelled.
            guard let first = try await group.next() else {
                throw TimedOut()
            }
            group.cancelAll()
            return first
        }
    }

    /// Stops listening (or thinking) without logging anything.
    func cancel() {
        listener.cancel()
        work?.cancel()
        phase = .idle
    }

    /// Takes back the last voice action and hides the banner.
    ///
    /// - Parameter logger: The logger that applied it.
    func undo(using logger: VoiceLogger) {
        if case .done(_, let change) = phase {
            logger.undo(change)
        }
        phase = .idle
    }

    /// Hides the result banner.
    func dismissBanner() {
        switch phase {
        case .done, .failed:
            phase = .idle
        case .idle, .listening, .thinking:
            break
        }
    }
}
