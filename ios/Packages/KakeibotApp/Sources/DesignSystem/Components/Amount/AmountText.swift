import Core
import SwiftUI

public struct AmountText: View {
    let amount: Int
    let type: Entry.Kind?

    public init(
        _ amount: Int,
        type: Entry.Kind? = nil
    ) {
        self.amount = amount
        self.type = type
    }

    public var body: some View {
        Text(Self.text(amount, type: type))
            .monospacedDigit()
            .foregroundStyle(color)
    }
}

public extension AmountText {
    static func text(
        _ amount: Int,
        type: Entry.Kind? = nil
    ) -> String {
        let number = abs(amount).formatted(.number.locale(locale))
        return "\(sign(of: amount, type: type))¥\(number)"
    }
}

private extension AmountText {
    static let locale = Locale(identifier: "ja_JP")

    static func sign(
        of amount: Int,
        type: Entry.Kind?
    ) -> String {
        if amount < 0 {
            "−"
        } else if type == .income {
            "+"
        } else {
            ""
        }
    }

    var color: Color {
        switch type {
        case .income: Palette.gold
        case .transfer: Palette.mist
        case .expense, nil: Palette.champagne
        }
    }
}

#Preview {
    VStack(alignment: .trailing) {
        AmountText(980, type: .expense)
        AmountText(250_000, type: .income)
        AmountText(3000, type: .transfer)
        AmountText(1_234_567)
        AmountText(-24800)
    }
    .padding()
    .background(Palette.night)
}
