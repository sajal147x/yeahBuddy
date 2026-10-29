import SwiftUI

/// One value as a screen shows it: the number, with a small label underneath,
/// e.g. "1,650 kg" over "Volume". Pure data, so screens can build rows of these.
struct StatValue: Identifiable {
    /// The formatted number, e.g. "1,650".
    let number: String
    /// An optional unit shown smaller after the number, e.g. "kg".
    var unit: String? = nil
    /// The caption under the number, e.g. "Volume".
    let label: String

    /// Stable identity for `ForEach`; labels are unique within a row.
    var id: String { label }
}

/// A number with a small label under it. Put several in an HStack for a row of totals.
struct Stat: View {
    /// The number, already styled (usually via `Text.amount`).
    let value: Text
    /// The caption under the number, e.g. "Volume".
    let label: String

    /// Creates a stat from any `Text`, e.g. `Text(date, style: .timer)` which ticks by itself.
    ///
    /// - Parameters:
    ///   - value: The number to show, with its font already applied.
    ///   - label: The caption.
    init(value: Text, label: String) {
        self.value = value
        self.label = label
    }

    /// Creates a stat from plain values, styled with small decimals and unit.
    ///
    /// - Parameters:
    ///   - stat: The number, unit and label.
    ///   - size: Point size of the number's whole part.
    init(_ stat: StatValue, size: CGFloat = 28) {
        self.init(value: .amount(stat.number, unit: stat.unit, size: size), label: stat.label)
    }

    /// The number stacked over its label, left-aligned and filling its share of the row.
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            value
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)
                // Shrinks long values like "12,450 kg" instead of wrapping or clipping.
                .minimumScaleFactor(0.6)
                // Digits roll when the value changes.
                .contentTransition(.numericText())
            Text(label)
                .font(.label)
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    HStack {
        Stat(StatValue(number: "1,650", unit: "kg", label: "Volume"))
        Stat(StatValue(number: "12", label: "Sets"))
    }
    .card()
    .padding()
    .background(Color.canvas)
}
