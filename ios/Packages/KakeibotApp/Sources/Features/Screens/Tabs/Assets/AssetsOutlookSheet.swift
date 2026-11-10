import Core
import DesignSystem
import SwiftUI

struct AssetsOutlookSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeStyle.corner) private var corner
    @Environment(\.themeStyle.rowSpacing) private var rowSpacing

    let model: AssetsModel
    let onOpen: (Entry.ID) -> Void
    let onOpenRecurring: (Recurring.ID) -> Void

    var body: some View {
        FittedSheet {
            content
        }
    }
}

extension AssetsOutlookSheet {
    var content: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("今月これからの出入り")
                    .textFont(.subheadline, weight: .semibold)
                    .foregroundStyle(Palette.subtext)

                Text("\(model.outlook.end.monthDayText) までの、固定費のこれからの回と、日付が明日以降の記録です。")
                    .textFont(.caption)
                    .foregroundStyle(Palette.subtext)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !model.outlook.items.isEmpty {
                itemList
            }

            total

            if !model.outlook.later.isEmpty {
                laterList
            }
        }
    }
}

private extension AssetsOutlookSheet {
    var itemList: some View {
        VStack(spacing: 0) {
            ForEach(model.outlook.items) { item in
                Button {
                    open(item)
                } label: {
                    row(
                        date: item.date,
                        title: item.title,
                        wallet: item.wallet,
                        change: item.change,
                        balance: item.balance,
                        isRecurring: item.isRecurring
                    )
                }
                .buttonStyle(.plain)
                .overlay(alignment: .top) {
                    if item.id != model.outlook.items.first?.id {
                        Hairline()
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .card()
        .sharesTextScale(id: model.outlook.items)
    }

    var laterList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("月末より先の予定")
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)

            VStack(spacing: 0) {
                ForEach(model.outlook.later) { plan in
                    Button {
                        onOpen(plan.id)
                        dismiss()
                    } label: {
                        row(
                            date: plan.date,
                            title: plan.title,
                            wallet: plan.wallet,
                            change: plan.change,
                            balance: nil,
                            isRecurring: false
                        )
                    }
                    .buttonStyle(.plain)
                    .overlay(alignment: .top) {
                        if plan.id != model.outlook.later.first?.id {
                            Hairline()
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .card()
            .sharesTextScale(id: model.outlook.later)
        }
    }

    var before: some View {
        Text("\(AmountText.text(model.total)) →")
            .textFont(.caption)
            .monospacedDigit()
            .foregroundStyle(Palette.subtext)
            .fixedSize()
    }

    var after: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("月末の見込み")
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)
                .fixedSize()

            AmountText(
                model.outlook.total,
                font: .size(.headline, weight: .bold),
                color: model.outlook.total < 0 ? Palette.rose : Palette.accentStrong
            )
            .lineLimit(1)
            .minimumScaleFactor(0.5)
        }
    }

    var total: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                before

                Spacer(minLength: 8)

                after
                    .fixedSize()
            }

            VStack(alignment: .trailing, spacing: 4) {
                before
                    .frame(maxWidth: .infinity, alignment: .leading)

                after
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            Palette.faint,
            in: .rect(cornerRadius: corner.radius(16))
        )
    }

    func row(
        date: LocalDate,
        title: String,
        wallet: String?,
        change: Int,
        balance: Int?,
        isRecurring: Bool
    ) -> some View {
        HStack(spacing: 12) {
            Text(date.monthDayText)
                .textFont(.caption, weight: .semibold)
                .monospacedDigit()
                .foregroundStyle(Palette.accent)
                .frame(minWidth: 40, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    if isRecurring {
                        Image(systemName: "repeat")
                            .sansFont(.micro, weight: .semibold)
                            .foregroundStyle(Palette.accent)
                    }

                    Text(title)
                        .textFont(.subheadline)
                        .foregroundStyle(Palette.text)
                        .sharedTextScale()
                }

                Text(caption(on: date, wallet: wallet))
                    .textFont(.caption)
                    .foregroundStyle(Palette.subtext)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.vertical, rowSpacing.padding)

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 4) {
                AmountText(
                    change,
                    font: .size(.body),
                    sign: .plus,
                    color: change > 0 ? Palette.accent : Palette.accentStrong
                )
                .lineLimit(1)
                .minimumScaleFactor(0.5)

                if let balance {
                    Text("残り \(AmountText.text(balance))")
                        .textFont(.caption2)
                        .monospacedDigit()
                        .foregroundStyle(balance < 0 ? Palette.rose : Palette.subtext)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .layoutPriority(1)
        }
        .frame(minHeight: rowSpacing.minHeight)
        .contentShape(.rect)
    }
}

private extension AssetsOutlookSheet {
    func open(_ item: AssetsModel.OutlookItem) {
        switch item.source {
        case let .plan(id): onOpen(id)
        case let .recurring(id, _): onOpenRecurring(id)
        }

        dismiss()
    }

    func caption(
        on date: LocalDate,
        wallet: String?
    ) -> String {
        let days = BillText.days(until: date, today: model.today)

        guard let wallet else {
            return days
        }

        return "\(days) · \(wallet)"
    }
}
