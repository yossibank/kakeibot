import Core
import SwiftUI

public struct EntryRow: View {
    let icon: Icon?
    let title: String
    let detail: String?
    let amount: Int
    let type: Entry.Kind

    public init(
        icon: Icon?,
        title: String,
        detail: String?,
        amount: Int,
        type: Entry.Kind
    ) {
        self.icon = icon
        self.title = title
        self.detail = detail
        self.amount = amount
        self.type = type
    }

    public var body: some View {
        HStack(spacing: 12) {
            IconBadge(icon)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)

                if let detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            AmountText(amount, type: type)
                .font(.body.weight(.semibold))
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    let now = Date()
    let food = Icon(emoji: "🍙", text: nil, color: "#E07A5F", createdAt: now, updatedAt: now)
    let salary = Icon(emoji: "💴", text: nil, color: "#2A9D8F", createdAt: now, updatedAt: now)

    List {
        EntryRow(icon: food, title: "食費", detail: "ランチ・財布", amount: 980, type: .expense)
        EntryRow(icon: salary, title: "給料", detail: "銀行", amount: 250_000, type: .income)
        EntryRow(icon: nil, title: "その他", detail: nil, amount: 120, type: .expense)
    }
}
