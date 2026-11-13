@testable import DesignSystem
import SwiftUI
import Testing

struct ViewFloatingInputTests {
    @Test
    func liftsTheCardAboveTheKeyboard() {
        let layer = CGRect(x: 0, y: 50, width: 375, height: 728)
        #expect(FloatingInputLayer<EmptyView>.lift(for: layer, keyboardTop: 467) == 311)
    }

    @Test
    func keepsTheCardDownWhenTheKeyboardIsHidden() {
        let layer = CGRect(x: 0, y: 50, width: 375, height: 728)
        #expect(FloatingInputLayer<EmptyView>.lift(for: layer, keyboardTop: 812) == 0)
    }
}
