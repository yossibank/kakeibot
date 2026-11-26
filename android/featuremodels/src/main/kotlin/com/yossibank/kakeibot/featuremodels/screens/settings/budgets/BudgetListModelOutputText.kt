package com.yossibank.kakeibot.featuremodels.screens.settings.budgets

import com.yossibank.kakeibot.featuremodels.shared.amount.AmountText
import com.yossibank.kakeibot.featuremodels.shared.amount.clamped
import com.yossibank.kakeibot.featuremodels.shared.period.PeriodText

val BudgetListModel.Output.periodText: String
    get() = input.overview?.period?.let(PeriodText::range) ?: ""

val BudgetListModel.Output.startText: String
    get() = "${month?.month ?: ""}月（$periodText）から使う額"

val BudgetListModel.Output.categoriesNote: String
    get() = "合計 ${AmountText.text(amount = categoriesTotal)}"

val BudgetListModel.Output.unbudgetedNote: String
    get() = "${unbudgeted.size} カテゴリ"

val BudgetListModel.Output.recurringText: String
    get() {
        val amount = AmountText.text(amount = recurringExpense.clamped)
        return "この月の固定費は $amount。予算の目安にできます"
    }
