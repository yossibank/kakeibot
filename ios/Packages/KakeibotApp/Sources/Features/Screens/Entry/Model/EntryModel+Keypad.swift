import Core
import DesignSystem
import Foundation
import Store

public extension EntryModel {
    enum KeypadTarget: Hashable {
        case amount
        case fee
    }

    var activeCalculator: AmountCalculator {
        keypadTarget == .fee ? feeCalculator : calculator
    }

    var feeChoices: [Int] {
        feeChoicesMemo.value(for: historyGeneration) {
            recentFeeChoices
        }
    }

    var expressionText: String? {
        let calculator = activeCalculator

        if let note = calculator.taxNote {
            return "\(Self.number(note.base)) の税込み \(note.rate.rawValue)%"
        }

        guard calculator.hasOperation else {
            return nil
        }

        let parts = calculator.tokens.map { token in
            switch token {
            case let .number(number): Self.number(number)
            case let .operation(operation): operation.symbol
            }
        }

        return parts.joined(separator: " ")
    }

    func press(_ key: AmountCalculator.Key) {
        switch keypadTarget {
        case .amount: calculator.press(key)
        case .fee: feeCalculator.press(key)
        }
    }

    func enter(_ target: KeypadTarget) {
        keypadTarget = type == .transfer ? target : .amount
    }

    func setFee(_ amount: Int) {
        feeCalculator = AmountCalculator(amount: amount)
    }
}

extension EntryModel {
    var recentFeeChoices: [Int] {
        let used = (history?.days ?? [])
            .lazy
            .flatMap(\.entries)
            .filter { $0.transferId != nil }
            .sorted { $0.createdAt > $1.createdAt }
            .map(\.amount)

        var seen: Set<Int> = []

        let ordered = (used + FeeChoiceRow.defaultChoices).filter { seen.insert($0).inserted }

        return Array(ordered.prefix(FeeChoiceRow.defaultChoices.count))
    }
}

private extension EntryModel {
    static let numberLocale = Locale(identifier: "ja_JP")

    static func number(_ value: Int) -> String {
        value.formatted(.number.locale(numberLocale))
    }
}
