import Core
@testable import DesignSystem
import Testing

struct KeypadTests {
    @Test
    func mapsTypedDigits() {
        #expect(Keypad.key(typed: "0") == .digit(0))
        #expect(Keypad.key(typed: "9") == .digit(9))
    }

    @Test
    func mapsTypedOperations() {
        #expect(Keypad.key(typed: "+") == .operation(.add))
        #expect(Keypad.key(typed: "-") == .operation(.subtract))
        #expect(Keypad.key(typed: "*") == .operation(.multiply))
        #expect(Keypad.key(typed: "/") == .operation(.divide))
    }

    @Test
    func mapsReturnAndDelete() {
        #expect(Keypad.key(typed: "=") == .equals)
        #expect(Keypad.key(typed: "\r") == .equals)
        #expect(Keypad.key(typed: "\u{7F}") == .delete)
    }

    @Test
    func ignoresOtherCharacters() {
        #expect(Keypad.key(typed: "a") == nil)
        #expect(Keypad.key(typed: "12") == nil)
        #expect(Keypad.key(typed: "") == nil)
    }
}
