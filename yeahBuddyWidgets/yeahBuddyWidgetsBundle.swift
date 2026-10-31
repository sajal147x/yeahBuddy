import SwiftUI
import WidgetKit

/// The widget extension's entry point. It holds only the workout Live Activity; there are no
/// home-screen widgets.
@main
struct yeahBuddyWidgetsBundle: WidgetBundle {
    /// The widgets this extension provides.
    var body: some Widget {
        WorkoutLiveActivity()
    }
}
