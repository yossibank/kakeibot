import Core
import DesignSystem
import Foundation
import Store

public extension EntryModel {
    struct SaveLabel: Equatable {
        public let title: String
        public let amount: String?
        public let category: String?
        public let day: String?
        public let wallets: String?
        public let fee: String?

        public init(
            title: String,
            amount: String? = nil,
            category: String? = nil,
            day: String? = nil,
            wallets: String? = nil,
            fee: String? = nil
        ) {
            self.title = title
            self.amount = amount
            self.category = category
            self.day = day
            self.wallets = wallets
            self.fee = fee
        }
    }

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
        type.name
    }

    var budgetUsage: BudgetUsage? {
        guard type == .expense else {
            return nil
        }

        return monthOverview.budgetUsage
    }

    var budgetUsageAfterSave: BudgetUsage? {
        guard let usage = budgetUsage else {
            return nil
        }

        let totals = monthTotals { $0.type == .expense }

        return BudgetUsage(
            budget: usage.baseBudget,
            carryover: usage.carryover,
            spent: usage.spent - totals.current + totals.after,
            today: Self.today,
            periodEnd: monthOverview.period.upperBound
        )
    }

    var budgetText: String? {
        guard
            let usage = budgetUsage,
            let after = budgetUsageAfterSave
        else {
            return nil
        }

        guard after.spent != usage.spent else {
            return "\(usage.remainingTitle) \(usage.remainingAmountText)"
        }

        let title = usage.isOver ? "予算オーバー" : "今月あと"

        let label = switch (usage.isOver, after.isOver) {
        case (false, true): "オーバー "
        case (true, false): "あと "
        default: ""
        }

        return "\(title) \(usage.remainingAmountText) → \(label)\(after.remainingAmountText)"
    }

    var monthTotalText: String? {
        guard
            type != .transfer,
            budgetUsage == nil
        else {
            return nil
        }

        let totals = monthTotals { entry in
            entry.type == type && (categoryId == nil || entry.categoryId == categoryId)
        }

        let title = "今月の\(selectedCategory?.name ?? typeName)"

        guard totals.after != totals.current else {
            return "\(title) \(AmountText.text(totals.current))"
        }

        return "\(title) \(AmountText.text(totals.current)) → \(AmountText.text(totals.after))"
    }

    var monthOverview: MonthOverview {
        MonthOverview(
            list: history,
            budgets: budgets,
            recurrings: [],
            monthStartDay: monthStartDay,
            carryoverFrom: carryoverFrom,
            today: Self.today
        )
    }

    static func dateText(
        for date: LocalDate,
        today: LocalDate
    ) -> String {
        let text = weekdayText(for: date, today: today)

        switch date {
        case today: return "今日 \(text)"
        case today.adding(days: -1): return "昨日 \(text)"
        default: return text
        }
    }

    static func keypadDateText(
        for date: LocalDate,
        today: LocalDate
    ) -> String {
        date == today ? "今日" : weekdayText(for: date, today: today)
    }

    static func shortDateText(
        for date: LocalDate,
        today: LocalDate
    ) -> String {
        switch date {
        case today: "今日"
        case today.adding(days: -1): "昨日"
        default: PeriodText.day(date, today: today)
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

    func quickDate(today: LocalDate) -> LocalDate {
        date == today ? today.adding(days: -1) : today
    }

    func saveLabel(today: LocalDate) -> SaveLabel {
        if !isEditing {
            guard amount > 0 else {
                return SaveLabel(title: "金額を入れてください")
            }

            if type == .transfer,
               toWalletId == nil {
                return SaveLabel(title: "\(Self.destinationTitle)を選んでください")
            }
        }

        guard amount > 0 else {
            return SaveLabel(title: saveAction)
        }

        return SaveLabel(
            title: saveAction,
            amount: AmountText.text(amount),
            category: type == .transfer ? nil : selectedCategory?.name,
            day: Self.shortDateText(for: date, today: today),
            wallets: saveWallets,
            fee: fee > 0 ? "手数料 \(AmountText.text(fee))" : nil
        )
    }
}

private extension EntryModel {
    var saveAction: String {
        switch (isEditing, type) {
        case (true, _): "変更を保存"
        case (false, .transfer): "振り替える"
        case (false, _): "記録する"
        }
    }

    var saveWallets: String? {
        let source = wallet(walletId)?.name

        guard type == .transfer else {
            return source
        }

        guard
            let source,
            let destination = wallet(toWalletId)?.name
        else {
            return nil
        }

        return "\(source) → \(destination)"
    }

    static func weekdayText(
        for date: LocalDate,
        today: LocalDate
    ) -> String {
        "\(PeriodText.day(date, today: today))（\(date.weekday.shortName)）"
    }

    func monthTotals(matching isIncluded: (Entry) -> Bool) -> (current: Int, after: Int) {
        let period = monthOverview.period

        let entries = (history?.days ?? [])
            .filter { period.contains($0.date) }
            .flatMap(\.entries)
            .filter(isIncluded)

        let current = entries.reduce(0) { $0 + $1.amount }
        let previous = entries.first { $0.id == original?.id }?.amount ?? 0
        let added = period.contains(date) ? amount : 0

        return (current, current - previous + added)
    }
}
