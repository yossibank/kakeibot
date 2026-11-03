public struct AmountCalculator: Hashable, Sendable {
    public private(set) var tokens: [Token]
    public private(set) var taxNote: TaxNote?

    private var isShowingResult: Bool

    public init(amount: Int = 0) {
        let isPositive = amount > 0

        self.tokens = isPositive ? [.number(amount)] : []
        self.taxNote = nil
        self.isShowingResult = isPositive
    }
}

public extension AmountCalculator {
    enum Key: Hashable, Sendable {
        case digit(Int)
        case doubleZero
        case tripleZero
        case delete
        case clear
        case operation(Operation)
        case equals
        case tax(TaxRate)
    }

    enum Operation: String, CaseIterable, Sendable {
        case add
        case subtract
        case multiply
        case divide
    }

    enum TaxRate: Int, CaseIterable, Codable, Sendable {
        case reduced = 8
        case standard = 10
    }

    enum Token: Hashable, Sendable {
        case number(Int)
        case operation(Operation)
    }

    struct TaxNote: Hashable, Sendable {
        public let base: Int
        public let rate: TaxRate
    }

    static let maxValue = 999_999_999

    var value: Int {
        var total: Int128 = 0
        var pending = Operation.add

        for token in tokens {
            switch token {
            case let .number(number):
                let operand = Int128(number)
                total = pending.apply(total, operand)

            case let .operation(operation):
                pending = operation
            }
        }

        let limit = Int128(Self.maxValue)
        let lowerClamped = max(total, -limit)
        let clamped = min(lowerClamped, limit)

        return Int(clamped)
    }

    var amount: Int {
        let nonNegative = max(value, 0)
        return min(nonNegative, Self.maxValue)
    }

    var hasOperation: Bool {
        tokens.contains { token in
            if case .operation = token {
                return true
            }

            return false
        }
    }

    mutating func press(_ key: Key) {
        taxNote = nil

        switch key {
        case let .digit(digit): append(digit: digit, shift: 10)
        case .doubleZero: append(digit: 0, shift: 100)
        case .tripleZero: append(digit: 0, shift: 1000)
        case .delete: deleteLast()
        case .clear: clear()
        case let .operation(operation): append(operation)
        case .equals: settle()
        case let .tax(rate): applyTax(rate)
        }
    }
}

private extension AmountCalculator {
    mutating func append(
        digit: Int,
        shift: Int
    ) {
        if isShowingResult {
            clear()
        }

        guard case let .number(number) = tokens.last else {
            if shift == 10 {
                tokens.append(.number(digit))
            }

            return
        }

        let next = number * shift + digit

        if next <= Self.maxValue {
            tokens[tokens.count - 1] = .number(next)
        }
    }

    mutating func deleteLast() {
        isShowingResult = false

        guard let last = tokens.last else {
            return
        }

        tokens.removeLast()

        if case let .number(number) = last,
           number >= 10 {
            let shortened = number / 10
            tokens.append(.number(shortened))
        }
    }

    mutating func clear() {
        tokens = []
        isShowingResult = false
    }

    mutating func append(_ operation: Operation) {
        isShowingResult = false

        switch tokens.last {
        case .none:
            return

        case .operation:
            tokens[tokens.count - 1] = .operation(operation)

        case .number:
            tokens.append(.operation(operation))
        }
    }

    mutating func settle() {
        if case .operation = tokens.last {
            tokens.removeLast()
        }

        let amount = amount

        tokens = amount > 0 ? [.number(amount)] : []
        isShowingResult = true
    }

    mutating func applyTax(_ rate: TaxRate) {
        settle()

        guard case let .number(base) = tokens.last else {
            return
        }

        let withTax = base * (100 + rate.rawValue) / 100
        let taxed = min(withTax, Self.maxValue)

        tokens = [.number(taxed)]
        taxNote = TaxNote(base: base, rate: rate)
    }
}

private extension AmountCalculator.Operation {
    static let ceiling = Int128.max / 2

    func apply(
        _ lhs: Int128,
        _ rhs: Int128
    ) -> Int128 {
        switch self {
        case .add: lhs + rhs
        case .subtract: lhs - rhs
        case .multiply: multiply(lhs, rhs)
        case .divide: rhs == 0 ? lhs : lhs / rhs
        }
    }

    func multiply(
        _ lhs: Int128,
        _ rhs: Int128
    ) -> Int128 {
        let (product, overflow) = lhs.multipliedReportingOverflow(by: rhs)

        guard !overflow else {
            return (lhs < 0) == (rhs < 0) ? Self.ceiling : -Self.ceiling
        }

        let lowerClamped = max(product, -Self.ceiling)

        return min(lowerClamped, Self.ceiling)
    }
}
