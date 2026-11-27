import Core
import DesignSystem
import FeatureModels
import SwiftUI

extension EntryWalletPanel {
    var billSection: some View {
        let shape = RoundedRectangle(cornerRadius: corner.radius(16))
        let ring = shown.isBillOpen ? Palette.accent : Palette.line

        return VStack(alignment: .leading, spacing: 0) {
            billHeader

            if shown.isBillOpen {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        ForEach(model.output.billChoices) { choice in
                            billButton(choice)
                        }
                    }

                    if let billNote {
                        Text(billNote)
                            .textFont(.caption2)
                            .foregroundStyle(Palette.subtext)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 4)
                    }
                }
                .padding([.horizontal, .bottom], 8)
                .transition(.opacity)
            }
        }
        .background(Palette.panel.opacity(.strong), in: shape)
        .overlay {
            shape
                .stroke(ring, lineWidth: 1)
        }
    }
}

private extension EntryWalletPanel {
    var billHeader: some View {
        Button {
            withAnimation(.snappy) {
                model.state.openBills(!shown.isBillOpen)
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .textFont(.subheadline)
                    .foregroundStyle(Palette.accent)

                if let date = model.output.selectedBillDate {
                    Text("\(date.monthDayText) に引き落とし")
                        .textFont(.subheadline, weight: .medium)
                        .foregroundStyle(Palette.text)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                if let shiftTitle {
                    Text(shiftTitle)
                        .textFont(.caption2, weight: .semibold)
                        .foregroundStyle(Palette.accentStrong)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Palette.accent.opacity(.subtle), in: .capsule)
                }

                Spacer(minLength: 0)

                if !shown.isBillOpen {
                    Text("変える")
                        .textFont(.caption, weight: .semibold)
                        .foregroundStyle(Palette.accent)
                }

                Image(systemName: shown.isBillOpen ? "chevron.up" : "chevron.right")
                    .textFont(.caption2, weight: .semibold)
                    .foregroundStyle(Palette.accent)
            }
            .padding(.horizontal, 12)
            .frame(minHeight: 44)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    func billButton(_ choice: EntryModel.BillChoice) -> some View {
        let isSelected = model.output.selectedBillDate == choice.date
        let titleColor = isSelected ? Palette.accentStrong : Palette.subtext
        let fill = isSelected ? Palette.accent.opacity(.subtle) : Color.clear
        let ring = isSelected ? Palette.accent : Palette.line
        let shape = RoundedRectangle(cornerRadius: corner.radius(16))

        return Button {
            withAnimation(.snappy) {
                model.selectBill(choice.date)
            }
        } label: {
            VStack(spacing: 4) {
                FlipDate(choice.date, isSelected: isSelected)

                Text(choice.title)
                    .textFont(.caption2)
                    .foregroundStyle(titleColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(fill, in: shape)
            .overlay {
                shape
                    .stroke(ring, lineWidth: 1)
            }
            .contentShape(shape)
        }
        .buttonStyle(.plain)
    }
}

private extension EntryWalletPanel {
    var shiftTitle: String? {
        let choices = model.output.billChoices

        guard
            let chosen = choices.first(where: { $0.date == model.output.selectedBillDate }),
            chosen.date != choices.first?.date
        else {
            return nil
        }

        return chosen.title
    }

    var billNote: String? {
        let choices = model.output.billChoices
        let chosen = choices.first { $0.date == model.output.selectedBillDate }

        guard let chosen else {
            return nil
        }

        let day = chosen.date.monthDayText

        guard chosen.date == choices.first?.date else {
            return "カード会社の確定が遅れた分として、\(day) の引き落としに入れます"
        }

        let period = chosen.period.map(RecurringText.period) ?? ""

        return "\(period) の利用分として、\(day) に引き落とされます"
    }
}
