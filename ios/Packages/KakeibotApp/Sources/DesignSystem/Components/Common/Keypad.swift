import SwiftUI

@MainActor
public struct Keypad {
    let onKey: (Key) -> Void

    public init(onKey: @escaping (Key) -> Void) {
        self.onKey = onKey
    }
}

public extension Keypad {
    enum Key: Hashable, Sendable {
        case digit(Int)
        case doubleZero
        case delete
    }
}

extension Keypad: View {
    public var body: some View {
        Grid(horizontalSpacing: 8, verticalSpacing: 8) {
            ForEach(Self.rows, id: \.self) { row in
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
    static let rows: [[Key]] = [
        [.digit(7), .digit(8), .digit(9)],
        [.digit(4), .digit(5), .digit(6)],
        [.digit(1), .digit(2), .digit(3)],
        [.doubleZero, .digit(0), .delete]
    ]

    func button(for key: Key) -> some View {
        Button {
            onKey(key)
        } label: {
            label(for: key)
                .font(.title2.weight(.medium))
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(
                    .fill.tertiary,
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel(for: key))
    }

    @ViewBuilder
    func label(for key: Key) -> some View {
        switch key {
        case let .digit(value): Text("\(value)")
        case .doubleZero: Text("00")
        case .delete: Image(systemName: "delete.left")
        }
    }

    func accessibilityLabel(for key: Key) -> String {
        switch key {
        case let .digit(value): "\(value)"
        case .doubleZero: "00"
        case .delete: "1 文字消す"
        }
    }
}

#Preview {
    Keypad { _ in }
        .padding()
}
