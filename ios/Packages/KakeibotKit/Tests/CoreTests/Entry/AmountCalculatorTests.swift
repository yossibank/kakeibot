import Core
import Testing

struct AmountCalculatorTests {
    @Test(arguments: try cases)
    func calculatesKeys(fixture: KeysCase) throws {
        var calculator = AmountCalculator()

        for key in try fixture.keys.map(Self.key) {
            calculator.press(key)
        }

        #expect(calculator.amount == fixture.amount)
        #expect(Self.expression(of: calculator.tokens) == fixture.expression)
    }

    @Test
    func remembersTaxBaseUntilNextKey() {
        var calculator = AmountCalculator(amount: 1180)

        calculator.press(.tax(.standard))
        let note = calculator.taxNote

        calculator.press(.digit(1))

        #expect(note?.base == 1180)
        #expect(note?.rate == .standard)
        #expect(calculator.taxNote == nil)
    }

    @Test
    func startsFromExistingAmount() {
        var calculator = AmountCalculator(amount: 980)

        calculator.press(.operation(.add))
        calculator.press(.digit(2))

        #expect(calculator.amount == 982)
    }
}

extension AmountCalculatorTests {
    struct KeysCase: Decodable, Sendable {
        let keys: [String]
        let amount: Int
        let expression: String
    }

    enum KeyError: Error {
        case unknown(String)
    }
}

private extension AmountCalculatorTests {
    static var cases: [KeysCase] {
        get throws {
            try Fixture.load("entry/amount-calculator.json")
        }
    }

    static func key(_ text: String) throws -> AmountCalculator.Key {
        if let digit = Int(text), text.count == 1 {
            return .digit(digit)
        }

        switch text {
        case "00": return .doubleZero
        case "del": return .delete
        case "ac": return .clear
        case "+": return .operation(.add)
        case "-": return .operation(.subtract)
        case "*": return .operation(.multiply)
        case "/": return .operation(.divide)
        case "=": return .equals
        case "tax8": return .tax(.reduced)
        case "tax10": return .tax(.standard)
        default: throw KeyError.unknown(text)
        }
    }

    static func expression(of tokens: [AmountCalculator.Token]) -> String {
        let parts = tokens.map { token in
            switch token {
            case let .number(number): String(number)
            case .operation(.add): "+"
            case .operation(.subtract): "-"
            case .operation(.multiply): "*"
            case .operation(.divide): "/"
            }
        }

        return parts.joined(separator: " ")
    }
}
