import Observation

/// A request from the Live Activity's Add Set button to show the Add Set pop-up.
///
/// The button opens the app wherever it was. Each screen on the way handles its part when
/// `isPending` turns on: Root switches to Home, Home opens the workout, the workout opens the
/// current exercise, and that exercise's card shows the pop-up and clears the request.
@Observable
final class AddSetRequest {
    /// True from the button tap until a card has shown the pop-up (or there is nothing to show).
    var isPending = false
}
