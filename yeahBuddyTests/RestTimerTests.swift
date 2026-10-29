import Testing
@testable import yeahBuddy

@MainActor
struct RestTimerTests {
    let clock = TestClock()

    func makeTimer() -> RestTimer {
        RestTimer(now: { [clock] in clock.now })
    }

    @Test func countsDownFromTheStartingDuration() {
        let timer = makeTimer()
        #expect(timer.remaining == 0)
        #expect(!timer.isRunning)

        timer.start(seconds: 90)
        clock.advance(by: 30)

        #expect(timer.remaining == 60)
        #expect(timer.isRunning)
    }

    @Test func stopsAtZeroOnceTimeIsUp() {
        let timer = makeTimer()
        timer.start(seconds: 90)

        clock.advance(by: 100)

        #expect(timer.remaining == 0)
        #expect(!timer.isRunning)
    }

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

    @Test func skippingEndsTheRestImmediately() {
        let timer = makeTimer()
        timer.start(seconds: 90)

        timer.skip()

        #expect(!timer.isRunning)
    }
}
