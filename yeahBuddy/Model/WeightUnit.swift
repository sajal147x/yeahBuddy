import Foundation

/// How weights are shown and entered. Storage is always kilograms, so switching units never
/// rewrites saved data.
nonisolated enum WeightUnit: String, CaseIterable, Identifiable {
    case kilograms = "kg"
    case pounds = "lb"

    var id: String { rawValue }

    private static let poundsPerKilogram = 2.20462262

    /// Converts a value the user entered in this unit into kilograms for storage.
    func kilograms(from value: Double) -> Double {
        switch self {
        case .kilograms:
            return value
        case .pounds:
            return value / Self.poundsPerKilogram
        }
    }

    /// Converts stored kilograms into this unit.
    func value(fromKilograms kg: Double) -> Double {
        switch self {
        case .kilograms:
            return kg
        case .pounds:
            return kg * Self.poundsPerKilogram
        }
    }

    /// How much one tap of a weight stepper changes the value: the smallest common plate pair.
    var step: Double {
        switch self {
        case .kilograms:
            return 2.5
        case .pounds:
            return 5
        }
    }

    /// Formats stored kilograms in this unit with at most one decimal, e.g. "80 kg", "176.4 lb".
    func format(kilograms kg: Double) -> String {
        let value = value(fromKilograms: kg).formatted(.number.precision(.fractionLength(0...1)))
        return "\(value) \(rawValue)"
    }
}
