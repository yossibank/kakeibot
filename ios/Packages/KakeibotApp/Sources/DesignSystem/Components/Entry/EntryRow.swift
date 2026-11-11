import Core
import SwiftUI

public struct EntryRow: View {
    @Environment(\.themeStyle.rowSpacing) private var rowSpacing

    let icon: Icon?
    let title: String
    let tag: String?
    let detail: String?
    let route: Route?
    let memo: String?
    let amount: Int
    let type: Entry.Kind
    let isRecurring: Bool

    public init(
        icon: Icon?,
        title: String,
        tag: String? = nil,
        detail: String?,
        route: Route? = nil,
        memo: String? = nil,
        amount: Int,
        type: Entry.Kind,
        isRecurring: Bool = false
    ) {
        self.icon = icon
        self.title = title
        self.tag = tag
        self.detail = detail
        self.route = route
        self.memo = memo
        self.amount = amount
        self.type = type
        self.isRecurring = isRecurring
    }

    public var body: some View {
        HStack(spacing: 12) {
            if icon == nil,
               type == .transfer {
                Image(systemName: "arrow.left.arrow.right")
                    .sansFont(.small, weight: .light)
                    .foregroundStyle(Palette.accent)
                    .frame(width: 28, height: 28)
            } else if let icon {
                IconBadge(icon, size: 28)
            } else {
                Color.clear
                    .frame(width: 28, height: 28)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(title)
                        .textFont(.subheadline)
                        .foregroundStyle(Palette.text)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .layoutPriority(1)

                    if isRecurring {
                        Image(systemName: "repeat")
                            .sansFont(.caption, weight: .semibold)
                            .foregroundStyle(Palette.accent.opacity(.strong))
                    }
                }

                if let tag {
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 8) {
                            tagCard(tag)

                            if let detail {
                                detailText(detail)
                                    .fixedSize()
                            }
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            if let detail {
                                detailText(detail)
                            }

                            tagCard(tag)
                        }
                    }
                } else if let detail, let memo, route == nil {
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            detailText(detail)
                                .fixedSize()

                            EntryMemo(memo)
                                .fixedSize()
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            detailText(detail)

                            EntryMemo(memo)
                        }
                    }
                } else if let detail {
                    detailText(detail)
                }

                if let route {
                    EntryRoute(source: route.source, destination: route.destination)
                }

                if let memo, tag != nil || detail == nil || route != nil {
                    EntryMemo(memo)
                }
            }
            .padding(.vertical, rowSpacing.padding)

            Spacer(minLength: 8)

            AmountText(amount, type: type, font: .size(.body))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .layoutPriority(2)
        }
        .frame(minHeight: rowSpacing.minHeight)
        .contentShape(.rect)
    }
}

private extension EntryRow {
    func tagCard(_ tag: String) -> some View {
        TagCard(tag, size: .small)
            .sharesTextScale(id: tag)
    }

    func detailText(_ detail: String) -> some View {
        Text(detail)
            .textFont(.caption)
            .foregroundStyle(Palette.subtext)
            .lineLimit(1)
            .truncationMode(.tail)
            .minimumScaleFactor(0.8)
    }
}

public extension EntryRow {
    struct Route: Equatable, Sendable {
        public let source: String
        public let destination: String

        public init(
            source: String,
            destination: String
        ) {
            self.source = source
            self.destination = destination
        }
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

    let route = EntryRow.Route(source: "三井住友銀行 普通預金", destination: "楽天ペイ チャージ用")

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
            detail: nil,
            route: route,
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
