import Core
import DesignSystem
import SwiftUI

extension AssetsView {
    var outlookButton: some View {
        let shape = RoundedRectangle(cornerRadius: corner.radius(12))

        return Button {
            isShowingOutlook = true
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Label("今月これから", systemImage: "calendar")
                    .textFont(.caption)
                    .foregroundStyle(Palette.subtext)

                VStack(spacing: 4) {
                    ForEach(outlookLines) { line in
                        outlookRow(line)
                    }
                }

                Hairline(thickness: 1)

                outlookTotal

                if let note = outlookNote {
                    Text(note.text)
                        .textFont(.caption2)
                        .monospacedDigit()
                        .foregroundStyle(note.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(12)
            .background(Palette.faint, in: shape)
            .overlay {
                shape.stroke(Palette.hairline, lineWidth: 1)
            }
            .contentShape(shape)
        }
        .buttonStyle(.plain)
    }
}

private extension AssetsView {
    struct OutlookLine: Identifiable {
        let id: Int
        let label: String
        let detail: String
        let amount: Int
    }

    struct OutlookNote {
        let text: String
        let color: Color
    }
}

private extension AssetsView {
    var outlookTotal: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("月末の見込み")
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)
                .fixedSize()

            Spacer(minLength: 8)

            AmountText(
                model.outlook.total,
                font: .size(.headline),
                color: model.outlook.total < 0 ? Palette.rose : Palette.accentStrong
            )
            .lineLimit(1)
            .minimumScaleFactor(0.5)

            Image(systemName: "chevron.right")
                .sansFont(.small)
                .foregroundStyle(Palette.hint)
        }
    }

    func outlookRow(_ line: OutlookLine) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(line.label)
                .textFont(.caption2)
                .foregroundStyle(Palette.subtext)
                .frame(width: 28, alignment: .leading)

            Text(line.detail)
                .textFont(.caption)
                .monospacedDigit()
                .foregroundStyle(Palette.text)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 8)

            AmountText(
                line.amount,
                font: .size(.body),
                sign: .plus,
                color: line.amount > 0 ? Palette.accent : Palette.accentStrong
            )
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .layoutPriority(1)
        }
    }
}

private extension AssetsView {
    var outlookLines: [OutlookLine] {
        let outlook = model.outlook
        let incomes = outlook.incomes
        let recurrings = outlook.recurringExpenses
        let plans = outlook.planExpenses
        let incomeLine = incomes.isEmpty
            ? nil
            : OutlookLine(
                id: 0,
                label: "入る",
                detail: Self.detail(of: incomes),
                amount: Self.sum(of: incomes)
            )

        let recurringLine = recurrings.isEmpty
            ? nil
            : OutlookLine(
                id: 1,
                label: "出る",
                detail: "固定費 \(recurrings.count) 件",
                amount: Self.sum(of: recurrings)
            )

        let planLine = plans.isEmpty
            ? nil
            : OutlookLine(
                id: 2,
                label: recurrings.isEmpty ? "出る" : "",
                detail: "予定の記録 \(plans.count) 件",
                amount: Self.sum(of: plans)
            )

        return [incomeLine, recurringLine, planLine].compactMap(\.self)
    }

    var outlookNote: OutlookNote? {
        let outlook = model.outlook

        if let lowest = outlook.lowest {
            return Self.note(of: lowest)
        }

        guard !outlook.later.isEmpty else {
            return nil
        }

        let change = AmountText.text(outlook.laterChange, sign: .plus)

        return OutlookNote(
            text: "月末より先の予定 \(outlook.later.count) 件 \(change)",
            color: Palette.subtext
        )
    }

    static func sum(of items: [AssetsModel.OutlookItem]) -> Int {
        items.reduce(0) { $0 + $1.change }
    }

    static func detail(of items: [AssetsModel.OutlookItem]) -> String {
        let largest = items.max { $0.change < $1.change }
        let title = largest?.title ?? ""
        return items.count > 1 ? "\(title) ほか \(items.count - 1) 件" : title
    }

    static func note(of lowest: AssetsModel.OutlookItem) -> OutlookNote {
        let day = lowest.date.monthDayText

        guard lowest.balance < 0 else {
            return OutlookNote(
                text: "いちばん少ない日 \(day) \(AmountText.text(lowest.balance))",
                color: Palette.subtext
            )
        }

        return OutlookNote(
            text: "\(day) に \(AmountText.text(abs(lowest.balance))) 足りなくなります",
            color: Palette.rose
        )
    }
}
