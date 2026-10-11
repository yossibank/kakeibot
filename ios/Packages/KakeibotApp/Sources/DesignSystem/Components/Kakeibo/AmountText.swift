import Core
import SwiftUI

@MainActor
public struct AmountText {
    let amount: Int
    let type: Entry.Kind?

    public init(
        _ amount: Int,
        type: Entry.Kind? = nil
    ) {
        self.amount = amount
        self.type = type
    }
}

public extension AmountText {
    static func text(
        _ amount: Int,
        type: Entry.Kind? = nil
    ) -> String {
        let sign = type == .income ? "+" : ""
        let number = amount.formatted(.number.locale(locale))
        return "\(sign)¥\(number)"
    }
}

extension AmountText: View {
    public var body: some View {
        Text(Self.text(amount, type: type))
            .monospacedDigit()
            .foregroundStyle(color)
    }
}

private extension AmountText {
    static let locale = Locale(identifier: "ja_JP")

    var color: Color {
        switch type {
        case .income: .green
        case .transfer: .secondary
        case .expense, nil: .primary
        }
    }
}

#Preview {
    VStack(alignment: .trailing) {
        AmountText(980, type: .expense)
        AmountText(250_000, type: .income)
        AmountText(3000, type: .transfer)
        AmountText(1_234_567)
    }
    .padding()
}
