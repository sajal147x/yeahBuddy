import SwiftUI

/// The app's three tabs, in the order they appear in the tab bar.
enum AppTab: String, TabBarItem {
    case home, history, exercises

    /// The label under the tab's icon.
    var title: String {
        switch self {
        case .home: return "Home"
        case .history: return "History"
        case .exercises: return "Exercises"
        }
    }

    /// The tab's SF Symbol.
    var systemImage: String {
        switch self {
        case .home: return "house"
        case .history: return "clock.arrow.circlepath"
        case .exercises: return "dumbbell"
        }
    }
}

/// The top-level screen: the selected tab's content with the floating tab bar over it.
struct RootView: View {
    // Which tab is showing. Starts on Home every launch.
    @State private var tab: AppTab = .home

    /// The current tab, with the tab bar pinned to the bottom safe area.
    var body: some View {
        // Each tab keeps its own navigation stack, so switching tabs doesn't lose your place.
        ZStack {
            page(HomeView(), for: .home)
            page(HistoryView(), for: .history)
            page(ExercisesView(), for: .exercises)
        }
        // A safe-area inset (not an overlay) so scrolling content stops above the bar
        // instead of hiding behind it.
        .safeAreaInset(edge: .bottom) {
            FloatingTabBar(selection: $tab)
                .padding(.bottom, Spacing.xs)
        }
    }

    /// Shows a tab's screen only while its tab is selected. Hidden tabs stay alive (keeping
    /// scroll position and navigation) but can't be seen, tapped or read by VoiceOver.
    ///
    /// - Parameters:
    ///   - content: The tab's screen.
    ///   - owner: The tab that screen belongs to.
    /// - Returns: The screen, visible only when `owner` is selected.
    private func page(_ content: some View, for owner: AppTab) -> some View {
        let isShowing = tab == owner
        return content
            .opacity(isShowing ? 1 : 0)
            .allowsHitTesting(isShowing)
            .accessibilityHidden(!isShowing)
    }
}
