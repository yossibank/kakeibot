import Core
import DesignSystem
import SwiftUI

struct RecurringLoanPlan: View {
    let model: RecurringEditModel
    let onMatch: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let total = model.plannedTotal,
               let end = model.scheduledEndDate {
                summary(total: total, end: end)
            }

            if let finalAmount = model.finalAmount {
                HStack {
                    Text("最後の回")
                        .textFont(.caption)
                        .foregroundStyle(Palette.subtext)

                    Spacer(minLength: 8)

                    AmountText(
                        finalAmount,
                        font: .style(.subheadline, weight: .semibold),
                        color: Palette.text
                    )
                }
            }

            note
        }
        .padding(16)
        .card()
    }
}

private extension RecurringLoanPlan {
    var totalTitle: String {
        model.isEditing ? "これから返す額" : "返す総額"
    }

    var noteText: String? {
        if model.usesAutoCount,
           let owed = model.loanOwed {
            return "残高 \(AmountText.text(owed)) から回数と最後の回を出しています"
        }

        guard let plan = model.autoPlan else {
            return nil
        }

        if let gap = model.balanceGap {
            return "残高と \(AmountText.text(abs(gap))) ずれています"
        }

        return model.plannedTotal == nil ? "残高から出すと、あと \(plan.count) 回で終わります" : nil
    }

    var canMatch: Bool {
        !model.usesAutoCount && model.autoPlan != nil
    }

    @ViewBuilder
    var note: some View {
        if let noteText {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(noteText)
                    .textFont(.caption)
                    .foregroundStyle(model.balanceGap == nil ? Palette.subtext : Palette.amber)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)

                if canMatch {
                    Button("合わせる", action: onMatch)
                        .textFont(.caption, weight: .bold)
                        .foregroundStyle(Palette.accent)
                        .buttonStyle(.plain)
                }
            }
        }
    }

    func summary(
        total: Int,
        end: LocalDate
    ) -> some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(totalTitle)
                    .textFont(.caption)
                    .foregroundStyle(Palette.subtext)

                AmountText(
                    total,
                    font: .size(.title, weight: .bold),
                    color: Palette.accentStrong
                )
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            }

            Spacer(minLength: 12)

            VStack(alignment: .trailing, spacing: 2) {
                Text("終わり")
                    .textFont(.caption)
                    .foregroundStyle(Palette.subtext)

                Text(verbatim: "\(end.year)年\(end.month)月")
                    .textFont(.subheadline, weight: .semibold)
                    .foregroundStyle(Palette.text)
            }
        }
    }
}
