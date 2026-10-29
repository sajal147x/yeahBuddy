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
}
