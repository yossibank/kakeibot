import DesignSystem
import Testing

struct TextScaleTests {
    @Test
    func keepsFullSizeWhenItFits() {
        #expect(TextScale.fitting(available: 120, needed: 100) == 1)
    }

    @Test
    func shrinksToTheAvailableWidth() {
        #expect(TextScale.fitting(available: 90, needed: 100) == 0.9)
    }

    @Test
    func roundsDownSoTheTextStillFits() {
        #expect(TextScale.fitting(available: 86.9, needed: 100) == 0.86)
    }

    @Test
    func stopsAtTheFloor() {
        #expect(TextScale.fitting(available: 40, needed: 100) == TextScale.floor)
    }

    @Test
    func ignoresUnmeasuredWidths() {
        #expect(TextScale.fitting(available: .infinity, needed: 100) == 1)

        #expect(TextScale.fitting(available: 50, needed: 0) == 1)
    }
}
