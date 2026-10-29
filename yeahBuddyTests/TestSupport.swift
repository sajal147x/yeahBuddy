import Foundation
import SwiftData
@testable import yeahBuddy

/// An in-memory store for one test.
///
/// Each test gets a fresh one (Swift Testing creates a new suite instance per test), so tests
/// never see each other's data and nothing touches the disk.
@MainActor
struct TestStore {
    /// The container to pass to the module under test.
    let container: ModelContainer

    /// Creates an empty in-memory store with the app's full schema.
    init() {
        container = try! ModelContainer(
            for: AppSchema.schema,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }
}

/// A clock the test moves by hand, so time-based behavior is exact and instant to test.
final class TestClock {
    /// The current time. Starts at a fixed date so results never depend on the real clock.
    var now = Date(timeIntervalSinceReferenceDate: 0)

    /// Moves time forward.
    ///
    /// - Parameter seconds: How far to move.
    func advance(by seconds: TimeInterval) {
        now = now.addingTimeInterval(seconds)
    }
}
