import Core
import SwiftUI

public struct EntryRow: View {
    let icon: Icon?
    let title: String
    let tag: String?
    let detail: String?
    let amount: Int
    let type: Entry.Kind

    public init(
        icon: Icon?,
        title: String,
        tag: String? = nil,
        detail: String?,
        amount: Int,
        type: Entry.Kind
    ) {
        self.icon = icon
        self.title = title
        self.tag = tag
        self.detail = detail
        self.amount = amount
        self.type = type
    }

    public var body: some View {
        HStack(spacing: 12) {
            Group {
                if icon == nil, type == .transfer {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 13, weight: .light))
                        .frame(width: 21, height: 21)
                } else {
                    IconImage(icon, size: 15)
                }
            }
            .foregroundStyle(Palette.gold)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(Palette.ink)

                if let tag {
                    TagCard(tag, size: .small)
                }

                if let detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(Palette.mist)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            AmountText(amount, type: type)
                .font(.system(size: 16, design: .serif))
        }
        .frame(minHeight: 48)
        .contentShape(.rect)
    }
}

#Preview {
    let now = Date()
    let food = Icon(
        emoji: nil,
        text: nil,
        glyph: .food,
        color: "#E07A5F",
        createdAt: now,
        updatedAt: now
    )
    let salary = Icon(
        emoji: nil,
        text: nil,
        glyph: .salary,
        color: "#2A9D8F",
        createdAt: now,
        updatedAt: now
    )

    VStack(spacing: 0) {
        EntryRow(
            icon: food,
            title: "食費",
            tag: "昼ごはん",
            detail: "ランチ・財布",
            amount: 980,
            type: .expense
        )
        EntryRow(
            icon: salary,
            title: "給料",
            detail: "銀行",
            amount: 250_000,
            type: .income
        )
        EntryRow(
            icon: nil,
            title: "振替",
            detail: "銀行 → 財布",
            amount: 20000,
            type: .transfer
        )
        EntryRow(
            icon: nil,
            title: "その他",
            detail: nil,
            amount: 120,
            type: .expense
        )
    }
    .padding()
    .background(Palette.night)
}
