import Core
import SwiftUI

public struct Keypad: View {
    let activeTax: AmountCalculator.TaxRate?
    let onKey: (AmountCalculator.Key) -> Void

    public init(
        activeTax: AmountCalculator.TaxRate? = nil,
        onKey: @escaping (AmountCalculator.Key) -> Void
    ) {
        self.activeTax = activeTax
        self.onKey = onKey
    }

    public var body: some View {
        Grid(horizontalSpacing: 6, verticalSpacing: 6) {
            ForEach(Array(Self.rows.enumerated()), id: \.offset) { _, row in
                GridRow {
                    ForEach(row, id: \.self) { key in
                        button(for: key)
                    }
                }
            }
        }
    }
}

private extension Keypad {
    func button(for key: AmountCalculator.Key) -> some View {
        let isActive = key == activeTax.map(AmountCalculator.Key.tax)

        return Button {
            onKey(key)
        } label: {
            label(for: key, isActive: isActive)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(
                    Self.background(for: key, isActive: isActive),
                    in: .rect(cornerRadius: 14)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Self.stroke(for: key, isActive: isActive), lineWidth: 0.75)
                }
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Self.accessibilityLabel(for: key))
    }

    @ViewBuilder
    func label(
        for key: AmountCalculator.Key,
        isActive: Bool
    ) -> some View {
        switch key {
        case let .digit(value):
            digitText(String(value))
        case .doubleZero:
            digitText("00")
        case .delete:
            Image(systemName: "delete.left")
                .font(.system(size: 20, weight: .light))
                .foregroundStyle(Palette.ink)
        case .clear:
            Text("AC")
                .font(.system(size: 15, weight: .medium, design: .serif))
                .tracking(3)
                .foregroundStyle(Palette.gold)
        case let .tax(rate):
            VStack(spacing: 0) {
                Text("税込")
                    .font(.system(size: 9))
                    .tracking(3)
                    .foregroundStyle(isActive ? Palette.gold : Palette.mist)

                HStack(alignment: .firstTextBaseline, spacing: 1) {
                    Text(String(rate.rawValue))
                        .font(.system(size: 20, design: .serif))

                    Text("%")
                        .font(.system(size: 11, design: .serif))
                }
                .foregroundStyle(isActive ? Palette.champagne : Palette.ink)
            }
        case let .operation(operation):
            Text(operation.symbol)
                .font(.system(size: 22))
                .foregroundStyle(Palette.champagne)
        case .equals:
            Text("＝")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Palette.nightBottom)
        }
    }

    func digitText(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 28, design: .serif))
            .foregroundStyle(Palette.ink)
    }
}

private extension Keypad {
    static let rows: [[AmountCalculator.Key]] = [
        [.clear, .tax(.reduced), .tax(.standard), .operation(.divide)],
        [.digit(1), .digit(2), .digit(3), .operation(.multiply)],
        [.digit(4), .digit(5), .digit(6), .operation(.subtract)],
        [.digit(7), .digit(8), .digit(9), .operation(.add)],
        [.doubleZero, .digit(0), .delete, .equals]
    ]

    static func background(
        for key: AmountCalculator.Key,
        isActive: Bool
    ) -> Color {
        switch key {
        case .digit, .doubleZero, .delete, .clear: Color.clear
        case .tax: isActive ? Palette.gold.opacity(0.1) : Color.clear
        case .operation: Palette.gold.opacity(0.12)
        case .equals: Palette.gold
        }
    }

    static func stroke(
        for key: AmountCalculator.Key,
        isActive: Bool
    ) -> Color {
        switch key {
        case .clear: Palette.gold.opacity(0.3)
        case .tax: isActive ? Palette.gold : Palette.gold.opacity(0.3)
        default: Color.clear
        }
    }

    static func accessibilityLabel(for key: AmountCalculator.Key) -> String {
        switch key {
        case let .digit(value): String(value)
        case .doubleZero: "00"
        case .delete: "1 文字消す"
        case .clear: "全部消す"
        case let .tax(rate): "税込み \(rate.rawValue)%"
        case let .operation(operation): operation.name
        case .equals: "計算する"
        }
    }
}

public extension AmountCalculator.Operation {
    var symbol: String {
        switch self {
        case .add: "＋"
        case .subtract: "−"
        case .multiply: "×"
        case .divide: "÷"
        }
    }
}

private extension AmountCalculator.Operation {
    var name: String {
        switch self {
        case .add: "足す"
        case .subtract: "引く"
        case .multiply: "掛ける"
        case .divide: "割る"
        }
    }
}

#Preview {
    Keypad(activeTax: .standard) { _ in }
        .padding()
        .background(Palette.night)
}
