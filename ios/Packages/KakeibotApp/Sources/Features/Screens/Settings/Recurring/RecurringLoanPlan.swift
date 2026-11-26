import Core
import DesignSystem
import FeatureModels
import SwiftUI

struct RecurringLoanPlan: View {
    let model: RecurringEditModel
    let onMatch: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let total = model.output.plannedTotal,
               let end = model.output.scheduledEndDate {
                summary(total: total, end: end)
            }

            if let finalAmount = model.output.finalAmount {
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
    @ViewBuilder
    var note: some View {
        if let noteText {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(noteText)
                    .textFont(.caption)
                    .foregroundStyle(model.output.balanceGap == nil
                        ? Palette.subtext
                        : Palette.amber)
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

private extension RecurringLoanPlan {
    var totalTitle: String {
        model.flow.output.isEditing ? "これから返す額" : "返す総額"
    }

    var noteText: String? {
        if model.output.usesAutoCount,
           let owed = model.output.loanOwed {
            return "残高 \(Yen.text(owed)) から回数と最後の回を出しています"
        }

        guard let plan = model.output.autoPlan else {
            return nil
        }

        if let gap = model.output.balanceGap {
            return "残高と \(Yen.text(abs(gap))) ずれています"
        }

        return model.output.plannedTotal == nil ? "残高から出すと、あと \(plan.count) 回で終わります" : nil
    }

    var canMatch: Bool {
        !model.output.usesAutoCount && model.output.autoPlan != nil
    }
}
