#if DEBUG
import Core
import DesignSystem
import SwiftUI

enum DebugComponent: CaseIterable, Identifiable {
    case amount
    case icon
    case entryRow
    case keypad
    case dial
    case ringButton

    var id: Self {
        self
    }
}

@MainActor
extension DebugComponent {
    var title: String {
        switch self {
        case .amount: "金額"
        case .icon: "アイコン"
        case .entryRow: "記録の 1 行"
        case .keypad: "テンキー"
        case .dial: "ダイヤルの目盛り"
        case .ringButton: "輪のボタン"
        }
    }

    @ViewBuilder
    var page: some View {
        switch self {
        case .amount: amountPage
        case .icon: iconPage
        case .entryRow: entryRowPage
        case .keypad: keypadPage
        case .dial: dialPage
        case .ringButton: ringButtonPage
        }
    }
}

@MainActor
private extension DebugComponent {
    static let food = icon(glyph: .food)
    static let salary = icon(glyph: .salary)
    static let emoji = icon(emoji: "🍙")
    static let text = icon(text: "給料")

    var amountPage: some View {
        List {
            AmountText(980, type: .expense)
            AmountText(250_000, type: .income)
            AmountText(3000, type: .transfer)
            AmountText(1_234_567)
        }
    }

    var iconPage: some View {
        List {
            Section("絵柄") {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible()), count: 4),
                    spacing: 16
                ) {
                    ForEach(Icon.Glyph.allCases, id: \.self) { glyph in
                        let icon = Self.icon(glyph: glyph)

                        VStack(spacing: 4) {
                            IconBadge(icon)

                            Text(glyph.rawValue)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.vertical, 8)
            }

            Section("絵文字と文字") {
                HStack(spacing: 16) {
                    IconBadge(Self.emoji)
                    IconBadge(Self.text)
                    IconBadge(nil)
                }
            }
        }
    }

    var entryRowPage: some View {
        List {
            EntryRow(
                icon: Self.food,
                title: "食費",
                detail: "ランチ・財布",
                amount: 980,
                type: .expense
            )

            EntryRow(
                icon: Self.salary,
                title: "給料",
                detail: "銀行",
                amount: 250_000,
                type: .income
            )

            EntryRow(
                icon: nil,
                title: "その他",
                detail: nil,
                amount: 120,
                type: .expense
            )
        }
    }

    var keypadPage: some View {
        VStack {
            Spacer()

            Keypad { _ in }
        }
        .padding()
        .background(Palette.night)
    }

    var dialPage: some View {
        ZStack {
            DialTicks(count: 60, length: 9)
                .stroke(Palette.gold.opacity(0.85), lineWidth: 1)

            DialTicks(count: 12, length: 14)
                .stroke(Palette.champagne, lineWidth: 1.5)
        }
        .frame(width: 214, height: 214)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.night)
    }

    var ringButtonPage: some View {
        HStack(spacing: 24) {
            RingButton("キャンセル", systemImage: "xmark") {}

            RingButton("保存", systemImage: "checkmark", isProminent: true) {}

            RingButton("保存", systemImage: "checkmark", isProminent: true) {}
                .disabled(true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.night)
    }

    static func icon(
        glyph: Icon.Glyph? = nil,
        emoji: String? = nil,
        text: String? = nil
    ) -> Icon {
        let now = Date()

        return Icon(
            emoji: emoji,
            text: text,
            glyph: glyph,
            color: "#C9A465",
            createdAt: now,
            updatedAt: now
        )
    }
}
#endif
