import Core
import SwiftUI

public struct EntryRow: View {
    let icon: Icon?
    let title: String
    let tag: String?
    let detail: String?
    let memo: String?
    let amount: Int
    let type: Entry.Kind
    let isRecurring: Bool

    public init(
        icon: Icon?,
        title: String,
        tag: String? = nil,
        detail: String?,
        memo: String? = nil,
        amount: Int,
        type: Entry.Kind,
        isRecurring: Bool = false
    ) {
        self.icon = icon
        self.title = title
        self.tag = tag
        self.detail = detail
        self.memo = memo
        self.amount = amount
        self.type = type
        self.isRecurring = isRecurring
    }

    public var body: some View {
        HStack(spacing: 12) {
            Group {
                if icon == nil, type == .transfer {
                    Image(systemName: "arrow.left.arrow.right")
                        .sansFont(.small, weight: .light)
                        .frame(width: 21, height: 21)
                } else {
                    IconImage(icon, size: 15)
                }
            }
            .foregroundStyle(Palette.accent)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(title)
                        .textFont(.subheadline)
                        .foregroundStyle(Palette.text)
                        .layoutPriority(1)

                    if isRecurring {
                        Image(systemName: "repeat")
                            .sansFont(.caption, weight: .semibold)
                            .foregroundStyle(Palette.accent.opacity(.strong))
                    }

                    if let tag {
                        TagCard(tag, size: .small)
                    }

                    if let detail {
                        Text(detail)
                            .textFont(.caption)
                            .foregroundStyle(Palette.subtext)
                            .lineLimit(1)
                    }
                }

                if let memo {
                    EntryMemo(memo)
                }
            }
            .padding(.vertical, 6)

            Spacer(minLength: 8)

            AmountText(amount, type: type)
                .displayFont(.body)
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
            detail: "財布",
            memo: "同僚と駅前の新しいイタリアンでランチ。パスタとサラダのセット",
            amount: 980,
            type: .expense
        )

        EntryRow(
            icon: salary,
            title: "給料",
            detail: "銀行",
            amount: 250_000,
            type: .income,
            isRecurring: true
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
    .background(Palette.background)
}
