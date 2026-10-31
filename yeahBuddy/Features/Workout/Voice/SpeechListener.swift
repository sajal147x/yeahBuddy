@preconcurrency import AVFoundation
import Foundation
import Observation
import Speech

/// Listens to the microphone and transcribes on-device with `SpeechAnalyzer`, stopping by
/// itself once the user goes quiet.
///
/// One sentence per `listen()`: tap the mic, speak, pause, and the finished text comes back.
/// `transcript` updates live while speaking so the panel can show it.
@Observable
final class SpeechListener {
    /// What has been heard so far, including words still being recognized.
    private(set) var transcript = ""

    /// Why listening couldn't start.
    enum Failure: Error {
        /// The user said no to the microphone.
        case microphoneDenied
        /// This language isn't supported for on-device transcription.
        case unsupportedLanguage
    }

    // A pause this long after speech ends the sentence.
    private static let silenceToStop: Duration = .milliseconds(1500)
    // Give up if nothing at all is said in this time.
    private static let waitForSpeech: Duration = .seconds(6)
    // Hard cap, so a loud gym can't keep it listening forever.
    private static let longest: Duration = .seconds(15)

    private let engine = AVAudioEngine()
    // Feeds microphone buffers to the analyzer; nil when not listening.
    private var input: AsyncStream<AnalyzerInput>.Continuation?
    // Set to true by `cancel()` to end the current `listen()` early with no result.
    private var cancelled = false

    /// Records until the user pauses, then returns everything they said.
    ///
    /// The first call may download Apple's speech model for the user's language; that's a
    /// one-time system download, not a request from this app.
    ///
    /// - Returns: The final transcript; empty if nothing was said or it was cancelled.
    /// - Throws: `Failure` when the microphone or language isn't available, or an audio error.
    func listen() async throws -> String {
        transcript = ""
        cancelled = false
        guard await AVAudioApplication.requestRecordPermission() else {
            throw Failure.microphoneDenied
        }
        let (transcriber, locale) = try await Self.makeTranscriber()
        // The app must claim the language before the system will check for or fetch its
        // model; without this the download check fails with "not subscribed".
        let alreadyReserved = await AssetInventory.reservedLocales.contains { $0.identifier(.bcp47) == locale.identifier(.bcp47) }
        if !alreadyReserved {
            _ = try await AssetInventory.reserve(locale: locale)
        }
        if let download = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) {
            try await download.downloadAndInstall()
        }
        let analyzer = SpeechAnalyzer(modules: [transcriber])
        let format = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [transcriber])

        let (stream, continuation) = AsyncStream<AnalyzerInput>.makeStream()
        input = continuation
        try startMicrophone(sendingTo: continuation, as: format)
        try await analyzer.start(inputSequence: stream)

        // Read results in the background, noting when the words last changed.
        var finished = ""
        var lastHeard: ContinuousClock.Instant?
        let reader = Task { @MainActor in
            try await Self.forEachResult(of: transcriber) { text, isFinal in
                if isFinal {
                    finished += text
                    transcript = finished
                } else {
                    transcript = finished + text
                }
                lastHeard = .now
            }
        }

        // Wait for a pause after speech, nothing said, the cap, or a cancel.
        let started = ContinuousClock.now
        while !cancelled {
            try? await Task.sleep(for: .milliseconds(200))
            let now = ContinuousClock.now
            if let lastHeard, now - lastHeard >= Self.silenceToStop {
                break
            }
            if lastHeard == nil && now - started >= Self.waitForSpeech {
                break
            }
            if now - started >= Self.longest {
                break
            }
        }

        stopMicrophone()
        if cancelled {
            await analyzer.cancelAndFinishNow()
            reader.cancel()
            transcript = ""
            return ""
        }
        // Let the analyzer finish the last words, then wait for their final result.
        try await analyzer.finalizeAndFinishThroughEndOfInput()
        _ = try? await reader.value
        return transcript.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// The speech module to use: `SpeechTranscriber` where the device supports it (newer
    /// iPhones), otherwise `DictationTranscriber`, which runs on more devices and in the
    /// simulator.
    ///
    /// - Returns: The module and the language it listens for.
    /// - Throws: `Failure.unsupportedLanguage` when neither supports the user's language.
    private static func makeTranscriber() async throws -> (any SpeechModule, Locale) {
        if SpeechTranscriber.isAvailable, let locale = await SpeechTranscriber.supportedLocale(equivalentTo: .current) {
            let transcriber = SpeechTranscriber(
                locale: locale,
                transcriptionOptions: [],
                reportingOptions: [.volatileResults, .fastResults],
                attributeOptions: []
            )
            return (transcriber, locale)
        }
        if let locale = await DictationTranscriber.supportedLocale(equivalentTo: .current) {
            let dictation = DictationTranscriber(
                locale: locale,
                contentHints: [.shortForm],
                transcriptionOptions: [],
                reportingOptions: [.volatileResults],
                attributeOptions: []
            )
            return (dictation, locale)
        }
        throw Failure.unsupportedLanguage
    }

    /// Reads a module's results, whichever kind of transcriber it is.
    ///
    /// - Parameters:
    ///   - module: The module from `makeTranscriber()`.
    ///   - body: Called with each result's text and whether it's final.
    private static func forEachResult(of module: any SpeechModule, _ body: (String, Bool) -> Void) async throws {
        if let transcriber = module as? SpeechTranscriber {
            for try await result in transcriber.results {
                body(String(result.text.characters), result.isFinal)
            }
        } else if let dictation = module as? DictationTranscriber {
            for try await result in dictation.results {
                body(String(result.text.characters), result.isFinal)
            }
        }
    }

    /// Stops listening now and makes `listen()` return an empty result.
    func cancel() {
        cancelled = true
    }

    // MARK: - Microphone

    /// Starts the microphone, converting each buffer to the analyzer's format.
    ///
    /// - Parameters:
    ///   - continuation: Where converted audio goes.
    ///   - format: The analyzer's preferred format; nil to pass audio through unchanged.
    private func startMicrophone(sendingTo continuation: AsyncStream<AnalyzerInput>.Continuation, as format: AVAudioFormat?) throws {
        let session = AVAudioSession.sharedInstance()
        // Duck rather than stop the user's music, and let AirPods' mic be used.
        try session.setCategory(.playAndRecord, mode: .spokenAudio, options: [.duckOthers, .defaultToSpeaker, .allowBluetoothHFP])
        try session.setActive(true)

        let node = engine.inputNode
        let micFormat = node.outputFormat(forBus: 0)
        node.installTap(onBus: 0, bufferSize: 4096, format: micFormat, block: Self.tap(from: micFormat, to: format, sendingTo: continuation))
        engine.prepare()
        try engine.start()
    }

    /// Stops the microphone, ends the audio stream and gives the user's music its volume back.
    private func stopMicrophone() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        input?.finish()
        input = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    /// The microphone callback. Built outside the main actor because the audio system calls
    /// it on its own thread.
    ///
    /// - Parameters:
    ///   - micFormat: The microphone's format.
    ///   - target: The analyzer's format, or nil to pass buffers through.
    ///   - continuation: Where converted audio goes.
    /// - Returns: The tap block.
    private nonisolated static func tap(
        from micFormat: AVAudioFormat,
        to target: AVAudioFormat?,
        sendingTo continuation: AsyncStream<AnalyzerInput>.Continuation
    ) -> AVAudioNodeTapBlock {
        guard let target, target != micFormat, let converter = AVAudioConverter(from: micFormat, to: target) else {
            return { buffer, _ in
                continuation.yield(AnalyzerInput(buffer: buffer))
            }
        }
        return { buffer, _ in
            let ratio = target.sampleRate / micFormat.sampleRate
            let capacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 1
            guard let converted = AVAudioPCMBuffer(pcmFormat: target, frameCapacity: capacity) else {
                return
            }
            // Hand the converter this one buffer, then report that there's no more for now.
            var handedOver = false
            var error: NSError?
            converter.convert(to: converted, error: &error) { _, status in
                if handedOver {
                    status.pointee = .noDataNow
                    return nil
                }
                handedOver = true
                status.pointee = .haveData
                return buffer
            }
            if error == nil && converted.frameLength > 0 {
                continuation.yield(AnalyzerInput(buffer: converted))
            }
        }
    }
}
