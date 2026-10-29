import Foundation
import SwiftData
@testable import yeahBuddy

/// An in-memory store for one test.
@MainActor
struct TestStore {
    let container: ModelContainer

    init() {
        container = try! ModelContainer(
            for: AppSchema.schema,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }
}

/// A clock the test moves by hand.
final class TestClock {
    var now = Date(timeIntervalSinceReferenceDate: 0)

    func advance(by seconds: TimeInterval) {
        now = now.addingTimeInterval(seconds)
    }
}
