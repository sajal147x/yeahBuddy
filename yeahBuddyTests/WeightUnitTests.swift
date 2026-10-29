import Testing
@testable import yeahBuddy

struct WeightUnitTests {
    @Test func poundsAreStoredAsKilogramsAndShownBackUnchanged() {
        let storedKg = WeightUnit.pounds.kilograms(from: 225)

        #expect(abs(storedKg - 102.058) < 0.001)
        #expect(WeightUnit.pounds.format(kilograms: storedKg) == "225 lb")
    }
}
