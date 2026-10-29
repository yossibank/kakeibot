import Core
import DesignSystem
import Foundation
import Store

public extension EntryModel {
    var memoPrompt: String {
        switch type {
        case .expense: "店名や買ったもの"
        case .income: "どこから入ったか"
        case .transfer: "何のための移動か"
        }
    }

    var memoHint: String {
        switch type {
        case .expense: "店名など"
        case .income: "入金元など"
        case .transfer: "用途など"
        }
    }

    var typeName: String {
        switch type {
        case .expense: "支出"
        case .income: "収入"
        case .transfer: "振替"
        }
    }

    var saveTitle: String {
        if isEditing {
            return "変更を保存"
        }

        guard amount > 0 else {
            return "金額を入れてください"
        }

        if type == .transfer,
           toWalletId == nil {
            return "\(Self.destinationTitle)を選んでください"
        }

        let action = type == .transfer ? "振り替える" : "記録する"

        return "\(AmountText.text(amount)) を\(action)"
    }

    var saveSubject: String? {
        guard
            !isEditing,
            amount > 0,
            type != .transfer
        else {
            return nil
        }

        return selectedCategory?.name
    }

    var budgetUsage: BudgetUsage? {
        guard type == .expense else {
            return nil
        }

        return monthOverview.budgetUsage
    }

    var monthTotalText: String? {
        guard
            type != .transfer,
            budgetUsage == nil
        else {
            return nil
        }

        let overview = monthOverview
        let month = history?.days.filter { overview.period.contains($0.date) } ?? []

        let entries = month
            .flatMap(\.entries)
            .filter { $0.type == type && (categoryId == nil || $0.categoryId == categoryId) }

        let current = entries.reduce(0) { $0 + $1.amount }
        let title = "今月の\(selectedCategory?.name ?? typeName)"
        let previous = entries.first { $0.id == original?.id }?.amount ?? 0
        let added = overview.period.contains(date) ? amount : 0
        let after = current - previous + added

        guard after != current else {
            return "\(title) \(AmountText.text(current))"
        }

        return "\(title) \(AmountText.text(current)) → \(AmountText.text(after))"
    }

    var monthOverview: MonthOverview {
        MonthOverview(
            list: history,
            budgets: budgets,
            recurrings: [],
            monthStartDay: monthStartDay,
            today: Self.today
        )
    }

    static func dateText(
        for date: LocalDate,
        today: LocalDate
    ) -> String {
        let day = PeriodText.day(date, today: today)
        let text = "\(day)（\(date.weekday.shortName)）"

        switch date {
        case today: return "今日 \(text)"
        case today.adding(days: -1): return "昨日 \(text)"
        default: return text
        }
    }

    static func dateTitle(
        for date: LocalDate,
        today: LocalDate
    ) -> String {
        let days = date.days(until: today)

        switch days {
        case 0, 1: return "日付"
        case 2...: return "日付・\(days)日前"
        default: return "日付・\(-days)日後"
        }
    }

    func saveDetail(today: LocalDate) -> String? {
        if type == .transfer,
           fee > 0 {
            return "手数料 \(AmountText.text(fee)) も記録"
        }

        guard
            !isEditing,
            canSave,
            type != .transfer,
            let wallet = wallet(walletId)
        else {
            return nil
        }

        let day = switch date {
        case today: "今日"
        case today.adding(days: -1): "昨日"
        default: PeriodText.day(date, today: today)
        }

        let direction = type == .income ? "へ" : "から"

        return "\(day)・\(wallet.name)\(direction)"
    }
}
