import SwiftUI

extension Text {
    /// A number styled the Sumeria way: whole part big, decimals and unit smaller,
    /// e.g. "82" big then ".5 kg" small.
    ///
    /// Works with any locale's decimal separator, so "82,5 kg" splits the same way.
    ///
    /// - Parameters:
    ///   - number: The already formatted number, e.g. "82.5" or "1,650".
    ///   - unit: An optional unit shown after the number, e.g. "kg".
    ///   - size: Point size of the whole part. Decimals and unit are drawn at 60% of it.
    /// - Returns: A single `Text`, so it can be used anywhere a `Text` can, e.g. in `Stat`.
    static func amount(_ number: String, unit: String? = nil, size: CGFloat) -> Text {
        let big = Font.system(size: size, weight: .bold).monospacedDigit()
        let small = Font.system(size: (size * 0.6).rounded(), weight: .semibold).monospacedDigit()
        let separator = Locale.current.decimalSeparator ?? "."
        // Split "82.5" into "82" and ".5"; numbers without decimals have no small part.
        var whole = number
        var fraction = ""
        if let range = number.range(of: separator) {
            whole = String(number[..<range.lowerBound])
            fraction = String(number[range.lowerBound...])
        }
        let unitText = unit.map { " \($0)" } ?? ""
        return Text("\(Text(whole).font(big))\(Text(fraction + unitText).font(small))")
    }
}

#Preview {
    VStack(alignment: .leading, spacing: Spacing.md) {
        Text.amount("82.5", unit: "kg", size: 40)
        Text.amount("1,650", unit: "kg", size: 28)
        Text.amount("12", size: 28)
    }
    .foregroundStyle(Color.textPrimary)
    .card()
    .padding()
    .background(Color.canvas)
}
