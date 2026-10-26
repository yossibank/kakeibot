import Core
import SwiftUI

public struct Keypad: View {
    @Environment(\.themeStyle.corner) private var corner

    let activeTax: AmountCalculator.TaxRate?
    let onDone: (() -> Void)?
    let onKey: (AmountCalculator.Key) -> Void

    public init(
        activeTax: AmountCalculator.TaxRate? = nil,
        onDone: (() -> Void)? = nil,
        onKey: @escaping (AmountCalculator.Key) -> Void
    ) {
        self.activeTax = activeTax
        self.onDone = onDone
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
            press(key)
        } label: {
            label(for: key, isActive: isActive)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(
                    Self.background(for: key, isActive: isActive),
                    in: .rect(cornerRadius: corner.radius(16))
                )
                .overlay {
                    RoundedRectangle(cornerRadius: corner.radius(16))
                        .stroke(
                            Self.stroke(for: key, isActive: isActive),
                            lineWidth: 0.75
                        )
                }
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: Self.clearPressDuration)
                .onEnded { _ in
                    if key == .delete {
                        onKey(.clear)
                    }
                }
        )
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
        case .tripleZero:
            digitText("000")
        case .delete, .clear:
            Image(systemName: "delete.left")
                .sansFont(.headline, weight: .light)
                .foregroundStyle(Palette.text)
        case let .tax(rate):
            let labelColor = isActive ? Palette.accent : Palette.subtext

            VStack(spacing: 0) {
                Text("税込")
                    .textFont(size: .micro)
                    .tracking(3)
                    .foregroundStyle(labelColor)

                HStack(alignment: .firstTextBaseline, spacing: 1) {
                    Text(String(rate.rawValue))
                        .displayFont(.headline)

                    Text("%")
                        .displayFont(.caption)
                }
                .foregroundStyle(isActive ? Palette.accentStrong : Palette.text)
            }
        case let .operation(operation):
            Text(operation.symbol)
                .textFont(size: .headline)
                .foregroundStyle(Palette.accentStrong)
        case .equals:
            if onDone == nil {
                Text("＝")
                    .textFont(size: .headline, weight: .semibold)
                    .foregroundStyle(Palette.backgroundBottom)
            } else {
                Image(systemName: "checkmark")
                    .sansFont(.headline, weight: .semibold)
                    .foregroundStyle(Palette.backgroundBottom)
            }
        }
    }

    func digitText(_ text: String) -> some View {
        Text(text)
            .displayFont(.title)
            .foregroundStyle(Palette.text)
    }

    func press(_ key: AmountCalculator.Key) {
        if key == .equals,
           let onDone {
            onDone()
        } else {
            onKey(key)
        }
    }
}

private extension Keypad {
    static let clearPressDuration = 0.5

    static let rows: [[AmountCalculator.Key]] = [
        [.delete, .tax(.reduced), .tax(.standard), .operation(.divide)],
        [.digit(1), .digit(2), .digit(3), .operation(.multiply)],
        [.digit(4), .digit(5), .digit(6), .operation(.subtract)],
        [.digit(7), .digit(8), .digit(9), .operation(.add)],
        [.doubleZero, .digit(0), .tripleZero, .equals]
    ]

    static func background(
        for key: AmountCalculator.Key,
        isActive: Bool
    ) -> Color {
        switch key {
        case .digit, .doubleZero, .tripleZero, .delete, .clear: Color.clear
        case .tax: isActive ? Palette.accent.opacity(.subtle) : Color.clear
        case .operation: Palette.accent.opacity(.subtle)
        case .equals: Palette.accent
        }
    }

    static func stroke(
        for key: AmountCalculator.Key,
        isActive: Bool
    ) -> Color {
        switch key {
        case .delete: Palette.accent.opacity(.muted)
        case .tax: isActive ? Palette.accent : Palette.accent.opacity(.muted)
        default: Color.clear
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

#Preview {
    Keypad(activeTax: .standard) { _ in }
        .padding()
        .background(Palette.background)
}
