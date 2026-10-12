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
            label(for: key)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(Self.background(for: key), in: .rect(cornerRadius: 14))
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isActive ? Palette.gold : Color.clear, lineWidth: 1)
                }
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Self.accessibilityLabel(for: key))
    }

    @ViewBuilder
    func label(for key: AmountCalculator.Key) -> some View {
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
            functionText("AC")
        case let .tax(rate):
            functionText("税込 \(rate.rawValue)%")
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

    func functionText(_ text: String) -> some View {
        Text(text)
            .font(.footnote.weight(.medium))
            .foregroundStyle(Palette.ink.opacity(0.85))
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

    static func background(for key: AmountCalculator.Key) -> Color {
        switch key {
        case .digit, .doubleZero, .delete: Color.clear
        case .clear, .tax: Color.white.opacity(0.05)
        case .operation: Palette.gold.opacity(0.12)
        case .equals: Palette.gold
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
