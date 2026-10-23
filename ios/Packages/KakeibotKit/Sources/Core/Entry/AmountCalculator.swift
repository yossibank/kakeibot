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

    enum TaxRate: Int, CaseIterable, Sendable {
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
        var total = 0
        var pending = Operation.add

        for token in tokens {
            switch token {
            case let .number(number):
                total = pending.apply(total, number)
            case let .operation(operation):
                pending = operation
            }
        }

        return total
    }

    var amount: Int {
        min(max(value, 0), Self.maxValue)
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

        if case let .number(number) = last, number >= 10 {
            tokens.append(.number(number / 10))
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

        let taxed = min(base * (100 + rate.rawValue) / 100, Self.maxValue)
        tokens = [.number(taxed)]
        taxNote = TaxNote(base: base, rate: rate)
    }
}

private extension AmountCalculator.Operation {
    func apply(
        _ lhs: Int,
        _ rhs: Int
    ) -> Int {
        let result = switch self {
        case .add: lhs + rhs
        case .subtract: lhs - rhs
        case .multiply: lhs * rhs
        case .divide: rhs == 0 ? lhs : lhs / rhs
        }

        let limit = AmountCalculator.maxValue
        return min(max(result, -limit), limit)
    }
}
