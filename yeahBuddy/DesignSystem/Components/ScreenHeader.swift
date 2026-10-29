import SwiftUI

/// The big left-aligned title at the top of each tab, with an optional line underneath
/// (e.g. "3 workouts this week") and an optional round button on the right.
struct ScreenHeader<Trailing: View>: View {
    /// The screen's name, e.g. "History".
    let title: String
    /// A short summary line under the title. Hidden when nil.
    var subtitle: String? = nil
    /// Content for the right side, usually a `CircleIconButton`.
    @ViewBuilder var trailing: Trailing

    /// Title and subtitle on the left, trailing content top-right.
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(.screenTitle)
                    .foregroundStyle(Color.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                }
            }
            Spacer()
            trailing
        }
        .padding(.top, Spacing.sm)
    }
}

extension ScreenHeader where Trailing == EmptyView {
    /// Creates a header with no trailing button.
    ///
    /// - Parameters:
    ///   - title: The screen's name.
    ///   - subtitle: An optional summary line.
    init(title: String, subtitle: String? = nil) {
        self.init(title: title, subtitle: subtitle) { EmptyView() }
    }
}

/// A round icon on the card surface, like Sumeria's "+" next to a title.
/// Just the look, so it can be a `Button` label or a `Menu` label.
struct CircleIcon: View {
    /// The SF Symbol to show.
    let systemImage: String

    /// A 44pt white circle with the icon in the middle.
    var body: some View {
        Image(systemName: systemImage)
            .font(.title3.weight(.semibold))
            .foregroundStyle(Color.textPrimary)
            .frame(width: 44, height: 44)
            .background(Color.surface, in: Circle())
            .shadow(color: Shadow.color, radius: 8, x: 0, y: 2)
    }
}

/// A `CircleIcon` that runs an action when tapped.
struct CircleIconButton: View {
    /// The SF Symbol to show.
    let systemImage: String
    /// The spoken name for VoiceOver.
    let accessibilityLabel: String
    /// What a tap does.
    let action: () -> Void

    /// The circle icon as a plain button.
    var body: some View {
        Button(action: action) {
            CircleIcon(systemImage: systemImage)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

/// A section heading between cards, e.g. "This week".
struct SectionTitle: View {
    /// The heading text.
    let text: String

    /// Creates a heading.
    ///
    /// - Parameter text: The heading text.
    init(_ text: String) {
        self.text = text
    }

    /// The text in the card-title font, with room above it to separate sections.
    var body: some View {
        Text(text)
            .font(.cardTitle)
            .foregroundStyle(Color.textPrimary)
            .padding(.top, Spacing.md)
    }
}

/// A rounded search field on the raised surface, for screens without a navigation bar.
struct SearchField: View {
    /// What the user has typed.
    @Binding var text: String
    /// The placeholder, e.g. "Search exercises".
    let prompt: String

    /// A magnifier, the text field, and a clear button once something is typed.
    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.textSecondary)
            TextField(prompt, text: $text)
                .foregroundStyle(Color.textPrimary)
                .autocorrectionDisabled()
            if !text.isEmpty {
                Button("Clear", systemImage: "xmark.circle.fill") {
                    text = ""
                }
                .labelStyle(.iconOnly)
                .foregroundStyle(Color.textSecondary)
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 44)
        .background(Color.surfaceRaised, in: RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
    }
}

#Preview {
    VStack {
        ScreenHeader(title: "History", subtitle: "12 workouts") {
            CircleIconButton(systemImage: "gearshape", accessibilityLabel: "Settings") {}
        }
        Spacer()
    }
    .padding()
    .background(Color.canvas)
}
