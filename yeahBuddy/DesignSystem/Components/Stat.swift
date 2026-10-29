import SwiftUI

/// A big number with a small uppercase label under it, e.g. "1,650 kg / VOLUME".
/// Put it in `.tile()` for a standalone score tile, or in an HStack for a row of scores.
struct Stat: View {
    let value: Text
    let label: String
    var font: Font = .score

    init(value: String, label: String, font: Font = .score) {
        self.init(value: Text(value), label: label, font: font)
    }

    /// For values that render themselves, e.g. `Text(date, style: .timer)`.
    init(value: Text, label: String, font: Font = .score) {
        self.value = value
        self.label = label
        self.font = font
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            value
                .font(font)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
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
