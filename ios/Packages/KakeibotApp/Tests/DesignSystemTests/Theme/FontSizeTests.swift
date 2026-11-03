import DesignSystem
import SwiftUI
import Testing

struct FontSizeTests {
    @Test
    func keepsSmallTextAtTheMinimum() {
        let small = Font.points(FontSize.micro.rawValue, scale: 0.9, shared: 1)
        let standard = Font.points(FontSize.micro.rawValue, scale: 1, shared: 1)
        let caption = Font.points(FontSize.caption.rawValue, scale: 0.9, shared: 1)
        #expect([small, standard, caption] == [10, 10, 10])
    }

    @Test
    func scalesTextAboveTheMinimum() {
        #expect(Font.points(FontSize.micro.rawValue, scale: 1.15, shared: 1) == 9 * 1.15)

        #expect(Font.points(FontSize.body.rawValue, scale: 0.9, shared: 1) == 16 * 0.9)
    }

    @Test
    func shrinksSharedTextBelowTheMinimum() {
        #expect(Font.points(FontSize.micro.rawValue, scale: 1, shared: 0.8) == 8)
    }
}
