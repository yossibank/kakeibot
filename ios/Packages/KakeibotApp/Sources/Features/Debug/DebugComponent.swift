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
    case chip
    case capsulePicker
    case primaryButton
    case pageDots
    case monthCalendar

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
        case .dial: "ダイヤル"
        case .ringButton: "輪のボタン"
        case .chip: "チップ"
        case .capsulePicker: "切り替え"
        case .primaryButton: "大きなボタン"
        case .pageDots: "ページの点"
        case .monthCalendar: "月のカレンダー"
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
        case .chip: chipPage
        case .capsulePicker: CapsulePickerPage()
        case .primaryButton: primaryButtonPage
        case .pageDots: pageDotsPage
        case .monthCalendar: MonthCalendarPage()
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
        VStack(spacing: 32) {
            DialFace(isActive: false)
                .frame(width: 200, height: 200)

            DialFace(isActive: true)
                .frame(width: 200, height: 200)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.night)
    }

    var ringButtonPage: some View {
        HStack(spacing: 24) {
            RingButton("閉じる", systemImage: "xmark") {}

            RingButton("保存", systemImage: "checkmark", style: .prominent) {}

            RingButton("消す", systemImage: "trash", style: .destructive) {}

            RingButton("保存", systemImage: "checkmark", style: .prominent) {}
                .disabled(true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.night)
    }

    var chipPage: some View {
        HStack {
            Chip("財布", systemImage: "wallet.bifold")
            Chip("ランチ", systemImage: "square.and.pencil")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.night)
    }

    var primaryButtonPage: some View {
        VStack(spacing: 16) {
            PrimaryButton("¥12,800 を記録する") {}

            PrimaryButton("金額を入れてください") {}
                .disabled(true)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.night)
    }

    var pageDotsPage: some View {
        VStack(spacing: 24) {
            PageDots(count: 2, current: 0)
            PageDots(count: 3, current: 1)
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

private struct CapsulePickerPage: View {
    @State private var selection = Entry.Kind.expense

    var body: some View {
        CapsulePicker(
            selection: $selection,
            options: [
                .init("支出", value: .expense),
                .init("収入", value: .income)
            ]
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.night)
    }
}

private struct MonthCalendarPage: View {
    @State private var selection = LocalDate(Date(), in: .current)

    var body: some View {
        MonthCalendar(selection: $selection, today: LocalDate(Date(), in: .current))
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Palette.night)
    }
}
#endif
