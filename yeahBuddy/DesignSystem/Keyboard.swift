import SwiftUI
import UIKit

/// Puts the keyboard away from anywhere, whichever field has focus.
///
/// Focus for the stepper fields lives inside each `NumberStepper`, so screens and cards that
/// want to end typing (a Done button, logging a set) can't reach it through SwiftUI focus.
/// Asking UIKit to resign the first responder ends editing wherever it is.
enum Keyboard {
    /// Hides the keyboard if it is showing; does nothing otherwise.
    @MainActor
    static func dismiss() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

/// Shows a Done chip pinned just above the keyboard while it is open.
///
/// Number pads have no return key. SwiftUI's own keyboard toolbar didn't appear on the
/// full-screen workout view, so this draws the button itself: a bottom safe-area inset, which
/// iOS lifts above the keyboard, shown only between the keyboard's show and hide events.
private struct KeyboardDoneButton: ViewModifier {
    // Whether the keyboard is on screen, from UIKit's keyboard notifications.
    @State private var keyboardShown = false

    /// The content with the Done chip inset at the bottom while the keyboard is up.
    ///
    /// - Parameter content: The screen to add the button to.
    /// - Returns: The screen, plus the chip whenever the keyboard shows.
    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom) {
                if keyboardShown {
                    HStack {
                        Spacer()
                        Button("Done") {
                            Keyboard.dismiss()
                        }
                        .buttonStyle(.chip)
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.sm)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                keyboardShown = true
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                keyboardShown = false
            }
    }
}

extension View {
    /// Adds a Done button above the keyboard for every text field on this screen.
    ///
    /// Apply it once to the screen, not to each field, so there is only ever one button.
    ///
    /// - Returns: The view with a Done chip that appears above the keyboard.
    func keyboardDoneButton() -> some View {
        modifier(KeyboardDoneButton())
    }
}
