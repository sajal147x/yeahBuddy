import Foundation
import Observation

/// Counts down rest between sets. It stores the end time rather than ticking, so it stays
/// correct while the app is in the background. Views redraw on their own schedule and read
/// `remaining`.
///
/// The timer lives in memory only, so it resets if the app is killed. That is acceptable
/// for v1; a Live Activity later would need it persisted.
@Observable
final class RestTimer {
    // When the current rest ends; nil when no rest is running.
    private var endsAt: Date?
    /// The full length of the current rest in seconds, including every extension; 0 when
    /// no rest has started. Stays put after the countdown hits zero, until the next start.
    private(set) var total: TimeInterval = 0
    // Injected so tests can control time; the app uses the real clock.
    private let now: () -> Date

    /// Creates a stopped timer.
    ///
    /// - Parameter now: The clock to count against. Defaults to the real time.
    init(now: @escaping () -> Date = Date.init) {
        self.now = now
    }

    /// Seconds left; 0 when not running. Never negative, even long after the rest ended.
    var remaining: TimeInterval {
        guard let endsAt else {
            return 0
        }
        return max(0, endsAt.timeIntervalSince(now()))
    }

    /// Whether a rest is counting down right now.
    var isRunning: Bool {
        remaining > 0
    }

    /// Starts a new countdown, replacing any rest already running.
    ///
    /// - Parameter seconds: How long to rest.
    func start(seconds: TimeInterval) {
        endsAt = now().addingTimeInterval(seconds)
        total = seconds
    }

    /// Adds time to the countdown, or starts a new one if the timer already ran out.
    ///
    /// - Parameter seconds: How much rest to add.
    func extend(by seconds: TimeInterval) {
        if isRunning {
            // Push the end time out and grow the total, so it reads e.g. 1:45 after one +15s.
            endsAt = now().addingTimeInterval(remaining + seconds)
            total += seconds
        } else {
            // The last rest already ran out: this is a new, short rest of its own.
            start(seconds: seconds)
        }
    }

    /// Ends the rest immediately, e.g. when the user is ready for the next set.
    func skip() {
        endsAt = nil
        total = 0
    }
}
