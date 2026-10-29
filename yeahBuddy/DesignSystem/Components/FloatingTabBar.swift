import SwiftUI

/// Anything that can be a tab in `FloatingTabBar`: it needs a name and an icon.
protocol TabBarItem: Hashable, CaseIterable where AllCases: RandomAccessCollection {
    /// The label under the icon, e.g. "History".
    var title: String { get }
    /// The SF Symbol for the tab.
    var systemImage: String { get }
}

/// A pill-shaped tab bar floating above the bottom edge, as in Sumeria. The selected tab
/// sits on a pale highlight. Works with any `TabBarItem` enum, so it can be reused.
struct FloatingTabBar<Tab: TabBarItem>: View {
    /// The tab currently showing.
    @Binding var selection: Tab

    /// One button per tab, in declaration order, on a floating capsule.
    var body: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(Array(Tab.allCases), id: \.self) { tab in
                button(for: tab)
            }
        }
        .padding(6)
        .background {
            Capsule()
                .fill(Color.surface)
                .shadow(color: Shadow.color, radius: Shadow.radius, x: 0, y: Shadow.y)
        }
        // A hairline edge keeps the bar visible in dark mode, where there's no shadow.
        .overlay(Capsule().strokeBorder(Color.divider, lineWidth: 1))
        .padding(.horizontal, Spacing.xl)
    }

    /// One tab: icon over label, on a highlight when selected.
    ///
    /// - Parameter tab: The tab this button selects.
    /// - Returns: The button.
    private func button(for tab: Tab) -> some View {
        let isSelected = tab == selection
        return Button {
            selection = tab
        } label: {
            VStack(spacing: 2) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    // Same box for every icon, so labels line up even when one symbol
                    // (like the dumbbell) is shorter than the others.
                    .frame(height: 24)
                Text(tab.title)
                    .font(.caption2.weight(.semibold))
            }
            .foregroundStyle(isSelected ? Color.textPrimary : Color.textSecondary)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(isSelected ? Color.surfaceRaised : .clear, in: Capsule())
            // The whole pill segment is tappable, not just the icon and text.
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .animation(.snappy, value: isSelected)
    }
}
