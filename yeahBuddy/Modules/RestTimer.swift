import Foundation
import Observation

/// Counts down rest between sets. It stores the end time rather than ticking, so it stays
/// correct while the app is in the background. Views redraw on their own schedule and read
/// `remaining`.
@Observable
final class RestTimer {
    private var endsAt: Date?
    private let now: () -> Date

    init(now: @escaping () -> Date = Date.init) {
        self.now = now
    }

    /// Seconds left; 0 when not running.
    var remaining: TimeInterval {
        guard let endsAt else {
            return 0
        }
        return max(0, endsAt.timeIntervalSince(now()))
    }

    var isRunning: Bool {
        remaining > 0
    }

    func start(seconds: TimeInterval) {
        endsAt = now().addingTimeInterval(seconds)
    }

    /// Adds time to the countdown, or starts a new one if the timer already ran out.
    func extend(by seconds: TimeInterval) {
        start(seconds: remaining + seconds)
    }

    func skip() {
        endsAt = nil
    }
}
