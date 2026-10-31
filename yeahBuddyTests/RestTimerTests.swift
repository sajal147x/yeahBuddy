import Foundation
import Testing
@testable import yeahBuddy

/// Behavior of `RestTimer`, driven by a hand-moved clock instead of real waiting.
@MainActor
struct RestTimerTests {
    /// The clock the timer counts against.
    let clock = TestClock()

    /// Creates a stopped timer on this test's clock.
    ///
    /// - Returns: A new `RestTimer`.
    func makeTimer() -> RestTimer {
        RestTimer(now: { [clock] in clock.now })
    }

    /// Remaining time drops as the clock moves.
    @Test func countsDownFromTheStartingDuration() {
        let timer = makeTimer()
        #expect(timer.remaining == 0)
        #expect(!timer.isRunning)

        timer.start(seconds: 90)
        clock.advance(by: 30)

        #expect(timer.remaining == 60)
        #expect(timer.isRunning)
    }

    /// Remaining time bottoms out at zero instead of going negative.
    @Test func stopsAtZeroOnceTimeIsUp() {
        let timer = makeTimer()
        timer.start(seconds: 90)

        clock.advance(by: 100)

        #expect(timer.remaining == 0)
        #expect(!timer.isRunning)
    }

    /// +15s adds to a running rest, or starts a new 15s rest after one ended.
    @Test func extendingAddsTimeOrStartsAFreshCountdown() {
        let timer = makeTimer()
        timer.start(seconds: 90)
        clock.advance(by: 80)

        timer.extend(by: 15)
        #expect(timer.remaining == 25)

        clock.advance(by: 60)
        timer.extend(by: 15)
        #expect(timer.remaining == 15)
    }

    /// Total is the full length of this rest, including every +15s, so the user can see how
    /// long they actually rested. A rest started after the last one ran out counts from zero.
    @Test func totalIncludesExtensionsAndResetsForANewRest() {
        let timer = makeTimer()
        #expect(timer.total == 0)

        timer.start(seconds: 90)
        clock.advance(by: 80)
        timer.extend(by: 15)
        timer.extend(by: 15)
        #expect(timer.total == 120)

        clock.advance(by: 60)
        timer.extend(by: 15)
        #expect(timer.total == 15)

        timer.skip()
        #expect(timer.total == 0)
    }

    /// The end time is exposed so the Live Activity can count down on its own; it's nil when
    /// no rest is running, including after the rest runs out.
    @Test func endsAtIsTheEndOfARunningRestOnly() {
        let timer = makeTimer()
        #expect(timer.endsAt == nil)

        timer.start(seconds: 90)
        timer.extend(by: 15)
        #expect(timer.endsAt == clock.now.addingTimeInterval(105))

        clock.advance(by: 200)
        #expect(timer.endsAt == nil)
    }

    /// Skip ends the rest right away.
    @Test func skippingEndsTheRestImmediately() {
        let timer = makeTimer()
        timer.start(seconds: 90)

        timer.skip()

        #expect(!timer.isRunning)
    }
}
