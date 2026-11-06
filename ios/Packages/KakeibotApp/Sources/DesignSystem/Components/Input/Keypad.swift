import Core
import SwiftUI

public struct Keypad: View {
    @State private var clearCount = 0

    @Environment(\.themeStyle.corner) private var corner

    let calculator: AmountCalculator
    let accessories: [Accessory]
    let onDone: (() -> Void)?
    let onKey: (AmountCalculator.Key) -> Void

    public init(
        calculator: AmountCalculator,
        accessories: [Accessory] = [],
        onDone: (() -> Void)? = nil,
        onKey: @escaping (AmountCalculator.Key) -> Void
    ) {
        self.calculator = calculator
        self.accessories = accessories
        self.onDone = onDone
        self.onKey = onKey
    }

    public var body: some View {
        let rows = Array(Self.rows.enumerated())

        Grid(horizontalSpacing: 8, verticalSpacing: 8) {
            ForEach(rows, id: \.offset) { _, row in
                GridRow {
                    ForEach(row, id: \.self) { key in
                        if let accessory = accessory(for: key) {
                            accessoryButton(accessory)
                        } else if key == .delete {
                            deleteButton
                        } else {
                            button(for: key)
                        }
                    }
                }
            }
        }
        .haptic(.impact(weight: .medium), trigger: clearCount)
    }
}

public extension Keypad {
    struct Accessory {
        let title: String
        let isActive: Bool
        let action: () -> Void

        public init(
            _ title: String,
            isActive: Bool = false,
            action: @escaping () -> Void
        ) {
            self.title = title
            self.isActive = isActive
            self.action = action
        }
    }
}

private extension Keypad {
    var deleteButton: some View {
        button(for: .delete)
            .simultaneousGesture(
                LongPressGesture(minimumDuration: Self.clearPressDuration)
                    .onEnded { _ in
                        clearCount += 1
                        onKey(.clear)
                    }
            )
    }

    func accessoryButton(_ accessory: Accessory) -> some View {
        let shape = RoundedRectangle(cornerRadius: corner.radius(16))
        let fill = accessory.isActive ? Palette.accent.opacity(.subtle) : Color.clear
        let rim = accessory.isActive ? Palette.accent : Palette.accent.opacity(.muted)

        return Button(action: accessory.action) {
            Text(accessory.title)
                .textFont(size: .body, weight: .semibold)
                .foregroundStyle(accessory.isActive ? Palette.accentStrong : Palette.text)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(fill, in: shape)
                .overlay {
                    shape
                        .stroke(rim, lineWidth: 0.75)
                }
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    func button(for key: AmountCalculator.Key) -> some View {
        let isActive = key == calculator.taxNote.map { .tax($0.rate) }

        return Button {
            press(key)
        } label: {
            label(for: key, isActive: isActive)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(
                    background(for: key, isActive: isActive),
                    in: .rect(cornerRadius: corner.radius(16))
                )
                .overlay {
                    RoundedRectangle(cornerRadius: corner.radius(16))
                        .stroke(stroke(for: key, isActive: isActive), lineWidth: 0.75)
                }
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
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
            let valueColor = isActive ? Palette.accentStrong : Palette.text

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
                .foregroundStyle(valueColor)
            }

        case let .operation(operation):
            Text(operation.symbol)
                .textFont(size: .headline)
                .foregroundStyle(Palette.accentStrong)

        case .equals:
            if !showsDone {
                Text("＝")
                    .textFont(size: .headline, weight: .semibold)
                    .foregroundStyle(Palette.backgroundBottom)
            } else {
                Image(systemName: "keyboard.chevron.compact.down")
                    .sansFont(.headline, weight: .light)
                    .foregroundStyle(Palette.text)
            }
        }
    }

    func digitText(_ text: String) -> some View {
        Text(text)
            .displayFont(.title)
            .foregroundStyle(Palette.text)
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

    var showsDone: Bool {
        onDone != nil && !calculator.hasOperation
    }

    func accessory(for key: AmountCalculator.Key) -> Accessory? {
        guard
            case let .tax(rate) = key,
            let index = AmountCalculator.TaxRate.allCases.firstIndex(of: rate),
            accessories.indices.contains(index)
        else {
            return nil
        }

        return accessories[index]
    }

    func background(
        for key: AmountCalculator.Key,
        isActive: Bool
    ) -> Color {
        switch key {
        case .digit, .doubleZero, .tripleZero, .delete, .clear: Color.clear
        case .tax: isActive ? Palette.accent.opacity(.subtle) : Color.clear
        case .operation: Palette.accent.opacity(.subtle)
        case .equals: showsDone ? Color.clear : Palette.accent
        }
    }

    func stroke(
        for key: AmountCalculator.Key,
        isActive: Bool
    ) -> Color {
        switch key {
        case .delete: Palette.accent.opacity(.muted)
        case .tax: isActive ? Palette.accent : Palette.accent.opacity(.muted)
        case .equals: showsDone ? Palette.accent.opacity(.muted) : Color.clear
        default: Color.clear
        }
    }

    func press(_ key: AmountCalculator.Key) {
        if key == .equals,
           showsDone,
           let onDone {
            onDone()
        } else {
            onKey(key)
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
    let calculator = AmountCalculator(amount: 1280)

    Keypad(calculator: calculator) { _ in }
        .padding()
        .background(Palette.background)
}
