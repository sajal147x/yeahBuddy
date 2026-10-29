import SwiftUI

/// A big number with a small uppercase label under it, e.g. "1,650 kg / VOLUME".
/// Put it in `.tile()` for a standalone score tile, or in an HStack for a row of scores.
struct Stat: View {
    /// The number to show, already formatted.
    let value: Text
    /// The caption under the number. Shown in uppercase.
    let label: String
    /// The number's font. Pick from the `score` fonts in `Theme`.
    var font: Font = .score

    /// Creates a stat from a plain string value.
    ///
    /// - Parameters:
    ///   - value: The formatted number, e.g. "1,650 kg".
    ///   - label: The caption, e.g. "Volume".
    ///   - font: The number's font.
    init(value: String, label: String, font: Font = .score) {
        self.init(value: Text(value), label: label, font: font)
    }

    /// Creates a stat from a `Text`, for values that render themselves,
    /// e.g. `Text(date, style: .timer)` which keeps ticking on its own.
    ///
    /// - Parameters:
    ///   - value: The text to show as the number.
    ///   - label: The caption.
    ///   - font: The number's font.
    init(value: Text, label: String, font: Font = .score) {
        self.value = value
        self.label = label
        self.font = font
    }

    /// The number stacked over its label, left-aligned and filling its share of the row.
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            value
                .font(font)
                .lineLimit(1)
                // Shrinks long values like "12,450 kg" instead of wrapping or clipping.
                .minimumScaleFactor(0.6)
                // Digits roll when the value changes, like a scoreboard.
                .contentTransition(.numericText())
            Text(label.uppercased())
                .font(.tileLabel)
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    HStack {
        Stat(value: "1,650 kg", label: "Volume").tile()
        Stat(value: "12", label: "Sets").tile()
    }
    .padding()
    .background(Color.canvas)
}
