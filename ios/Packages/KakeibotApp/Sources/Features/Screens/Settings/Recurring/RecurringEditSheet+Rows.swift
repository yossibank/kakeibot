import Core
import DesignSystem
import Store
import SwiftUI

extension RecurringEditSheet {
    var detailItems: [SettingsRowList<Panel>.Item] {
        transferItems + scheduleItems
    }
}

private extension RecurringEditSheet {
    var transferItems: [SettingsRowList<Panel>.Item] {
        guard model.type == .transfer else {
            return []
        }

        let fee = SettingsRowList<Panel>.Item(
            panel: .fee,
            systemImage: "yensign.circle",
            title: "手数料",
            value: model.fee > 0 ? AmountText.text(model.fee) : "なし",
            isEmpty: model.fee == 0,
            isAmount: true
        )

        guard model.canUseClosingDay else {
            return [fee]
        }

        let closing = SettingsRowList<Panel>.Item(
            panel: .closing,
            systemImage: "creditcard",
            title: "金額の決め方",
            value: RecurringText.closingDay(model.closingDay),
            isEmpty: model.closingDay == nil
        )

        return [closing, fee]
    }

    var scheduleItems: [SettingsRowList<Panel>.Item] {
        [
            .init(
                panel: .start,
                systemImage: "calendar",
                title: "始まり",
                value: RecurringText.date(model.startDate),
                isEmpty: false
            ),
            .init(
                panel: .end,
                systemImage: "calendar.badge.checkmark",
                title: "終わり",
                value: model.endDate.map(RecurringText.date) ?? "なし",
                isEmpty: model.endDate == nil
            ),
            .init(
                panel: .holiday,
                systemImage: "calendar.badge.exclamationmark",
                title: "休日なら",
                value: model.holidayShift.title,
                isEmpty: model.holidayShift == .none
            ),
            .init(
                panel: .remind,
                systemImage: "bell",
                title: "前に知らせる",
                value: RecurringText.remind(model.remindDaysBefore),
                isEmpty: model.remindDaysBefore == nil
            )
        ]
    }
}
