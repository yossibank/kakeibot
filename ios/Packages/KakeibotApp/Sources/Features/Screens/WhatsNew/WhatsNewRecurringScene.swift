import Core
import DesignSystem
import SwiftUI

struct WhatsNewRecurringScene: View {
    let kind: WhatsNewScene.Kind

    var body: some View {
        switch kind {
        case .recurringTabs:
            tabs
                .whatsNewTapped()

        case .recurringList:
            list

        default:
            row
                .whatsNewTapped()
        }
    }
}

private extension WhatsNewRecurringScene {
    struct Income {
        let name: String
        let amount: Int
        let day: String
    }

    static let kinds = ["支出", "収入", "振替"]

    static let incomes = [
        Income(name: "給料", amount: 250_000, day: "毎月 25 日"),
        Income(name: "副業", amount: 30000, day: "毎月 10 日")
    ]

    var row: some View {
        HStack(spacing: 8) {
            Image(systemName: "repeat")
                .foregroundStyle(Palette.accent)

            Text("固定費")
                .foregroundStyle(Palette.text)

            Spacer(minLength: 4)

            Image(systemName: "chevron.right")
                .foregroundStyle(Palette.hint)
        }
        .textFont(size: .caption, weight: .semibold)
        .padding(.horizontal, 12)
        .frame(height: 40)
        .card(cornerRadius: 12)
        .padding(.horizontal, 4)
    }

    var tabs: some View {
        HStack(spacing: 0) {
            ForEach(Self.kinds, id: \.self) { kind in
                let isSelected = kind == "収入"

                Text(kind)
                    .textFont(size: .caption, weight: isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? Palette.accentStrong : Palette.subtext)
                    .frame(maxWidth: .infinity)
                    .frame(height: 26)
                    .background(Palette.card.opacity(isSelected ? 1 : 0), in: .capsule)
            }
        }
        .padding(2)
        .background(Palette.accent.opacity(.subtle), in: .capsule)
        .padding(.horizontal, 8)
    }

    var list: some View {
        VStack(spacing: 8) {
            ForEach(Self.incomes, id: \.name) { income in
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(income.name)
                            .foregroundStyle(Palette.text)

                        Spacer(minLength: 4)

                        AmountText(
                            income.amount,
                            font: .size(.caption, weight: .semibold),
                            color: Palette.accentStrong
                        )
                    }
                    .textFont(size: .caption, weight: .semibold)

                    Text(income.day)
                        .textFont(size: .micro)
                        .foregroundStyle(Palette.subtext)
                }
                .padding(8)
                .card(cornerRadius: 8)
            }
        }
        .padding(.horizontal, 8)
    }
}
