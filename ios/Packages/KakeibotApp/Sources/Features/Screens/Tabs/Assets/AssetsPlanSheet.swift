import Core
import DesignSystem
import SwiftUI

struct AssetsPlanSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeStyle.corner) private var corner
    @Environment(\.themeStyle.rowSpacing) private var rowSpacing

    let model: AssetsModel
    let onOpen: (Entry.ID) -> Void

    var body: some View {
        FittedSheet {
            content
        }
    }
}

extension AssetsPlanSheet {
    var content: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("予定の記録")
                    .textFont(.subheadline, weight: .semibold)
                    .foregroundStyle(Palette.subtext)

                Text("日付が明日以降の記録です。その日になると手元のお金に入ります。")
                    .textFont(.caption)
                    .foregroundStyle(Palette.subtext)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 0) {
                ForEach(model.plans) { plan in
                    Button {
                        onOpen(plan.id)
                        dismiss()
                    } label: {
                        row(plan)
                    }
                    .buttonStyle(.plain)
                    .overlay(alignment: .top) {
                        if plan.id != model.plans.first?.id {
                            Hairline()
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .card()

            total
        }
    }
}

private extension AssetsPlanSheet {
    var before: some View {
        Text("\(AmountText.text(model.total)) →")
            .textFont(.caption)
            .monospacedDigit()
            .foregroundStyle(Palette.subtext)
            .fixedSize()
    }

    var after: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("予定を含めると")
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)
                .fixedSize()

            AmountText(
                model.plannedTotal,
                font: .size(.headline, weight: .bold),
                color: Palette.accentStrong
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

    func row(_ plan: AssetsModel.Plan) -> some View {
        HStack(spacing: 12) {
            Text(plan.date.monthDayText)
                .textFont(.caption, weight: .semibold)
                .monospacedDigit()
                .foregroundStyle(Palette.accent)
                .frame(minWidth: 40, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                Text(plan.title)
                    .textFont(.subheadline)
                    .foregroundStyle(Palette.text)
                    .lineLimit(1)

                Text(caption(of: plan))
                    .textFont(.caption)
                    .foregroundStyle(Palette.subtext)
                    .lineLimit(1)
            }
            .padding(.vertical, rowSpacing.padding)

            Spacer(minLength: 8)

            AmountText(
                plan.change,
                font: .size(.body),
                sign: .plus,
                color: color(of: plan)
            )
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .layoutPriority(1)
        }
        .frame(minHeight: rowSpacing.minHeight)
        .contentShape(.rect)
    }

    func color(of plan: AssetsModel.Plan) -> Color {
        plan.change > 0 ? Palette.accent : Palette.accentStrong
    }

    func caption(of plan: AssetsModel.Plan) -> String {
        let days = BillText.days(until: plan.date, today: model.today)

        guard let wallet = plan.wallet else {
            return days
        }

        return "\(days) · \(wallet)"
    }
}
