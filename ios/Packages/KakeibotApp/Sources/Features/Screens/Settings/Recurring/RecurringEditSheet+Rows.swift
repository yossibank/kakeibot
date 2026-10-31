import Core
import DesignSystem
import Store
import SwiftUI

extension RecurringEditSheet {
    var rowItems: [SettingsRowList<Panel>.Item] {
        [amountItem] + moneyItems + scheduleItems
    }
}

private extension RecurringEditSheet {
    var amountText: String {
        model.isCardBill ? "カードの利用分" : AmountText.text(model.amount)
    }

    var amountPanel: Panel {
        model.isCardBill ? .closing : .amount
    }

    var scheduleText: String {
        RecurringText.schedule(model.frequency, month: model.month, day: model.day)
    }

    var amountItem: SettingsRowList<Panel>.Item {
        let isEmpty = model.amount == 0 && !model.isCardBill

        return .init(
            panel: amountPanel,
            systemImage: "yensign",
            title: "金額",
            value: amountText,
            isEmpty: isEmpty,
            isAmount: true
        )
    }

    var moneyItems: [SettingsRowList<Panel>.Item] {
        let wallet = SettingsRowList<Panel>.Item(
            panel: .wallet,
            systemImage: "wallet.bifold",
            title: model.walletTitle,
            value: model.selectedWallet?.name ?? "選ぶ",
            isEmpty: model.selectedWallet == nil
        )

        guard model.type == .transfer else {
            let category = SettingsRowList<Panel>.Item(
                panel: .category,
                systemImage: "square.grid.2x2",
                title: "カテゴリ",
                value: model.selectedCategory?.name ?? "選ぶ",
                isEmpty: model.selectedCategory == nil
            )

            return [category, wallet]
        }

        let destination = SettingsRowList<Panel>.Item(
            panel: .destination,
            systemImage: "arrow.right.circle",
            title: RecurringEditModel.destinationTitle,
            value: model.selectedDestination?.name ?? "選ぶ",
            isEmpty: model.selectedDestination == nil
        )

        let fee = SettingsRowList<Panel>.Item(
            panel: .fee,
            systemImage: "yensign.circle",
            title: "手数料",
            value: model.fee > 0 ? AmountText.text(model.fee) : "なし",
            isEmpty: model.fee == 0,
            isAmount: true
        )

        guard model.canUseClosingDay else {
            return [wallet, destination, fee]
        }

        let closing = SettingsRowList<Panel>.Item(
            panel: .closing,
            systemImage: "creditcard",
            title: "金額の決め方",
            value: RecurringText.closingDay(model.closingDay),
            isEmpty: model.closingDay == nil
        )

        return [wallet, destination, closing, fee]
    }

    var scheduleItems: [SettingsRowList<Panel>.Item] {
        [
            .init(
                panel: .schedule,
                systemImage: "repeat",
                title: "繰り返し",
                value: scheduleText,
                isEmpty: false
            ),
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
