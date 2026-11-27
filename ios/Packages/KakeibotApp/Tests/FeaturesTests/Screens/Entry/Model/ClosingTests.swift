import FeatureModels
import Testing

struct ClosingTests {
    @Test
    func beginsAndCancelsClosing() {
        var closing = EntryModel.Closing()

        let before = closing.hasBegun
        closing.begin()
        let begun = closing.hasBegun
        closing.cancel()

        #expect(!before)
        #expect(begun)
        #expect(!closing.hasBegun)
    }
}
