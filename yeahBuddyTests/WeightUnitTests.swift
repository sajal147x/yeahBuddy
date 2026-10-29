import Testing
@testable import yeahBuddy

/// Converting and formatting weights between kilograms and pounds.
struct WeightUnitTests {
    /// 225 lb survives the round trip to kilograms and back without drifting to 224.9.
    @Test func poundsAreStoredAsKilogramsAndShownBackUnchanged() {
        let storedKg = WeightUnit.pounds.kilograms(from: 225)

        #expect(abs(storedKg - 102.058) < 0.001)
        #expect(WeightUnit.pounds.format(kilograms: storedKg) == "225 lb")
    }

    /// Regression: a new exercise in pounds started at 44.1 lb (20 kg converted) instead of a
    /// real bar. Each unit's starting weight is its standard empty barbell.
    @Test func startingWeightIsTheStandardBarInEachUnit() {
        #expect(WeightUnit.kilograms.emptyBar == 20)
        #expect(WeightUnit.pounds.emptyBar == 45)
    }
}
