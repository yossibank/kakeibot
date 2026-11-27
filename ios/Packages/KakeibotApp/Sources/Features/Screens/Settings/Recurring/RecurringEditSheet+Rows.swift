import Core
import DesignSystem
import FeatureModels
import SwiftUI

extension RecurringEditSheet {
    var detailItems: [SettingsRowList<Panel>.Item] {
        transferItems + scheduleItems
    }
}

private extension RecurringEditSheet {
    var transferItems: [SettingsRowList<Panel>.Item] {
        guard model.state.type == .transfer else {
            return []
        }

        let fee = SettingsRowList<Panel>.Item(
            panel: .fee,
            systemImage: "yensign.circle",
            title: "手数料",
            value: model.output.fee > 0 ? Yen.text(model.output.fee) : "なし",
            isEmpty: model.output.fee == 0,
            isAmount: true
        )

        guard !model.output.isLoanRepayment else {
            return loanItems + [fee]
        }

        guard model.output.canUseClosingDay else {
            return [fee]
        }

        let closing = SettingsRowList<Panel>.Item(
            panel: .closing,
            systemImage: "creditcard",
            title: "金額の決め方",
            value: RecurringText.closingDay(model.state.fields.schedule.closingDay),
            isEmpty: model.state.fields.schedule.closingDay == nil
        )

        return [closing, fee]
    }

    var loanItems: [SettingsRowList<Panel>.Item] {
        [
            .init(
                panel: .count,
                systemImage: "number",
                title: "回数",
                value: countText,
                isEmpty: model.output.repaymentCount == nil
            )
        ]
    }

    var countText: String {
        guard let count = model.output.repaymentCount else {
            return "決めない"
        }

        return model.output.usesAutoCount ? "自動 · \(count) 回" : "\(count) 回"
    }

    var scheduleItems: [SettingsRowList<Panel>.Item] {
        [
            .init(
                panel: .start,
                systemImage: "calendar",
                title: "始まり",
                value: RecurringText.date(model.state.fields.schedule.startDate),
                isEmpty: false
            ),
            .init(
                panel: .end,
                systemImage: "calendar.badge.checkmark",
                title: "終わり",
                value: model.output.scheduledEndDate.map(RecurringText.date) ?? "なし",
                isEmpty: model.output.scheduledEndDate == nil
            ),
            .init(
                panel: .holiday,
                systemImage: "calendar.badge.exclamationmark",
                title: "休日なら",
                value: model.state.fields.schedule.holidayShift.title,
                isEmpty: model.state.fields.schedule.holidayShift == .none
            ),
            .init(
                panel: .remind,
                systemImage: "bell",
                title: "前に知らせる",
                value: RecurringText.remind(model.state.fields.schedule.remindDaysBefore),
                isEmpty: model.state.fields.schedule.remindDaysBefore == nil
            )
        ]
    }
}
