import Foundation

/// How weights are shown and entered. Storage is always kilograms, so switching units never
/// rewrites saved data.
///
/// `nonisolated` because it is a pure value type with no UI state; it can be used from
/// any thread, including tests that are not on the main actor.
nonisolated enum WeightUnit: String, CaseIterable, Identifiable {
    case kilograms = "kg"
    case pounds = "lb"

    /// Stable identity for SwiftUI pickers; the raw value is unique per case.
    var id: String { rawValue }

    // The international avoirdupois pound is defined as exactly 0.45359237 kg.
    private static let poundsPerKilogram = 2.20462262

    /// Converts a value the user entered in this unit into kilograms for storage.
    ///
    /// - Parameter value: The weight in this unit, e.g. 225 for pounds.
    /// - Returns: The same weight in kilograms.
    func kilograms(from value: Double) -> Double {
        switch self {
        case .kilograms:
            return value
        case .pounds:
            return value / Self.poundsPerKilogram
        }
    }

    /// Converts stored kilograms into this unit.
    ///
    /// - Parameter kg: A stored weight in kilograms.
    /// - Returns: The same weight in this unit, unrounded.
    func value(fromKilograms kg: Double) -> Double {
        switch self {
        case .kilograms:
            return kg
        case .pounds:
            return kg * Self.poundsPerKilogram
        }
    }

    /// How much one tap of a weight stepper changes the value: the smallest common plate pair.
    /// Two 1.25 kg plates in metric gyms, two 2.5 lb plates in imperial ones.
    var step: Double {
        switch self {
        case .kilograms:
            return 2.5
        case .pounds:
            return 5
        }
    }

    /// The standard empty barbell in this unit: where a new exercise's weight starts.
    ///
    /// Each unit has its own bar rather than converting one: a metric Olympic bar is 20 kg,
    /// while gyms in pounds use a 45 lb bar. Converting 20 kg would give an odd 44.1 lb.
    var emptyBar: Double {
        switch self {
        case .kilograms:
            return 20
        case .pounds:
            return 45
        }
    }

    /// Formats stored kilograms in this unit with at most one decimal, e.g. "80 kg", "176.4 lb".
    ///
    /// Rounding to one decimal also hides the tiny error from converting pounds to kilograms
    /// and back, so 225 lb always shows as "225 lb".
    ///
    /// - Parameter kg: A stored weight in kilograms.
    /// - Returns: The weight with its unit, using the user's locale for digits and grouping.
    func format(kilograms kg: Double) -> String {
        "\(formatNumber(kilograms: kg)) \(rawValue)"
    }

    /// Like `format(kilograms:)` but without the unit, e.g. "82.5", for layouts that style
    /// the number and the unit separately.
    ///
    /// - Parameter kg: A stored weight in kilograms.
    /// - Returns: The number in this unit with at most one decimal.
    func formatNumber(kilograms kg: Double) -> String {
        value(fromKilograms: kg).formatted(.number.precision(.fractionLength(0...1)))
    }
}
