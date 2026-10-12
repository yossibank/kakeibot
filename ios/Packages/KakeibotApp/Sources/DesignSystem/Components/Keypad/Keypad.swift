import SwiftUI

public struct Keypad: View {
    let onKey: (Key) -> Void

    public init(onKey: @escaping (Key) -> Void) {
        self.onKey = onKey
    }

    public var body: some View {
        Grid(horizontalSpacing: 0, verticalSpacing: 0) {
            ForEach(Array(Self.rows.enumerated()), id: \.offset) { index, row in
                GridRow {
                    ForEach(row, id: \.self) { key in
                        button(for: key)
                    }
                }
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Palette.gold.opacity(index == 0 ? 0 : 0.15))
                        .frame(height: 0.5)
                }
            }
        }
    }
}

public extension Keypad {
    enum Key: Hashable, Sendable {
        case digit(Int)
        case doubleZero
        case delete
    }
}

private extension Keypad {
    func button(for key: Key) -> some View {
        Button {
            onKey(key)
        } label: {
            Group {
                switch key {
                case let .digit(value): Text("\(value)")
                case .doubleZero: Text("00")
                case .delete: Image(systemName: "delete.left").imageScale(.small)
                }
            }
            .font(.system(size: 28, weight: .regular, design: .serif))
            .foregroundStyle(Palette.ink)
            .frame(maxWidth: .infinity, minHeight: 56)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel(for: key))
    }
}

private extension Keypad {
    static let rows: [[Key]] = [
        [.digit(1), .digit(2), .digit(3)],
        [.digit(4), .digit(5), .digit(6)],
        [.digit(7), .digit(8), .digit(9)],
        [.doubleZero, .digit(0), .delete]
    ]

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
        .background(Palette.night)
}
