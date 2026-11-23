package com.yossibank.kakeibot.features.screens.settings.budgets

import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshotFlow
import com.yossibank.kakeibot.core.concepts.budget.BudgetUsage
import com.yossibank.kakeibot.core.concepts.budget.amount
import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.date.YearMonth
import com.yossibank.kakeibot.core.concepts.entry.AmountCalculator
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.entry.within
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.designsystem.components.text.AmountText
import com.yossibank.kakeibot.designsystem.components.text.clamped
import com.yossibank.kakeibot.features.shared.model.ModelTask
import com.yossibank.kakeibot.features.shared.period.PeriodText
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.queries.methods.categoryListUpdates
import com.yossibank.kakeibot.store.queries.methods.monthOverviewUpdates
import com.yossibank.kakeibot.store.queries.types.CategoryList
import com.yossibank.kakeibot.store.queries.types.EntryList
import com.yossibank.kakeibot.store.queries.types.MonthOverview
import com.yossibank.kakeibot.store.records.settingkeys.SettingKey
import com.yossibank.kakeibot.store.records.settingkeys.budgetCarryoverFrom
import com.yossibank.kakeibot.store.writes.methods.setBudget
import com.yossibank.kakeibot.store.writes.methods.setSetting
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.launch

class BudgetListModel(
    private val database: AppDatabase,
    private val entryList: Flow<EntryList>,
    today: LocalDate,
) {
    sealed interface Target {
        val categoryId: Identifier<EntryCategory>?
        val title: String

        data object Total : Target {
            override val categoryId: Identifier<EntryCategory>? = null
            override val title: String = "月全体の予算"
        }

        data class Category(
            val category: EntryCategory,
        ) : Target {
            override val categoryId: Identifier<EntryCategory> = category.id
            override val title: String = "${category.name}の予算"
        }
    }

    data class Cleared(
        val target: Target,
        val amount: Int,
        val month: YearMonth,
    )

    data class Suggestion(
        val title: String,
        val amount: Int,
    )

    var today: LocalDate by mutableStateOf(today)

    var overview: MonthOverview? by mutableStateOf(null)
        private set

    var categoryList: CategoryList? by mutableStateOf(null)
        private set

    var editing: Target? by mutableStateOf(null)
        private set

    var calculator by mutableStateOf(AmountCalculator())
        private set

    private val task = ModelTask()

    val message: String
        get() = task.message

    val month: YearMonth?
        get() = overview?.month

    val periodText: String
        get() = overview?.period?.let(PeriodText::range) ?: ""

    val startText: String
        get() = "${month?.month ?: ""}月（$periodText）から使う額"

    val categoriesNote: String
        get() = "合計 ${AmountText.text(amount = categoriesTotal)}"

    val unbudgetedNote: String
        get() = "${unbudgeted.size} カテゴリ"

    val recurringExpense: Long
        get() = overview?.recurringExpense ?: 0L

    val recurringText: String
        get() {
            val amount = AmountText.text(amount = recurringExpense.clamped)
            return "この月の固定費は $amount。予算の目安にできます"
        }

    val categories: List<EntryCategory> by derivedStateOf {
        categoryList?.categories.orEmpty().filter { category ->
            category.kind == EntryCategory.Kind.expense && category.archivedAt == null
        }
    }

    val budgeted: List<EntryCategory> by derivedStateOf {
        categories.filter { amount(it.id) != null }
    }

    val unbudgeted: List<EntryCategory> by derivedStateOf {
        categories
            .filter { amount(it.id) == null }
            .withIndex()
            .sortedWith(
                compareByDescending<IndexedValue<EntryCategory>> { spent(it.value.id) }
                    .thenBy { it.index },
            ).map { it.value }
    }

    private val monthSpent: Map<Identifier<EntryCategory>?, Long> by derivedStateOf {
        month?.let(::spentByCategory).orEmpty()
    }

    val totalAmount: Int?
        get() = amount(null)

    val isCarryoverOn: Boolean
        get() = overview?.carryoverFrom != null

    val carryover: Long
        get() = overview?.budgetCarryover ?: 0L

    val categoriesTotal: Int
        get() = categories.sumOf { amount(it.id) ?: 0 }

    val editingAmount: Int?
        get() = editing?.let { amount(it.categoryId) }

    val suggestions: List<Suggestion>
        get() {
            val target = editing ?: return emptyList()
            val month = month ?: return emptyList()
            val categoryId = target.categoryId
            val recurring = if (categoryId == null) recurringExpense else 0L
            val seen = mutableSetOf<Int>()

            return listOf(
                Suggestion(
                    title = "先月",
                    amount = spent(categoryId, month.adding(months = -1)).clamped,
                ),
                Suggestion(
                    title = "3 か月の平均",
                    amount = averageSpent(categoryId).clamped,
                ),
                Suggestion(
                    title = "固定費",
                    amount = recurring.clamped,
                ),
            ).filter { it.amount > 0 && seen.add(it.amount) }
        }

    val canSave: Boolean
        get() = calculator.amount > 0

    val isChanged: Boolean
        get() = editing != null && calculator.amount != (editingAmount ?: 0)

    val saveTitle: String
        get() = if (canSave) "${month?.month ?: ""}月からこの額にする" else "金額を入れてください"

    fun amount(categoryId: Identifier<EntryCategory>?): Int? {
        val month = month ?: return null
        return overview?.budgets?.amount(
            categoryId = categoryId,
            month = month,
        )
    }

    fun spent(categoryId: Identifier<EntryCategory>?): Long = monthSpent[categoryId] ?: 0L

    fun usage(categoryId: Identifier<EntryCategory>?): BudgetUsage? {
        val overview = overview ?: return null
        val budget = amount(categoryId) ?: return null

        return BudgetUsage(
            budget = budget,
            carryover = if (categoryId == null) carryover else 0L,
            spent = spent(categoryId),
            today = overview.today,
            periodEnd = overview.period.endInclusive,
        )
    }

    fun icon(category: EntryCategory) = categoryList?.icons?.get(category.iconId)

    @OptIn(ExperimentalCoroutinesApi::class)
    suspend fun observe() {
        coroutineScope {
            launch {
                database.categoryListUpdates().collect { categoryList = it }
            }

            snapshotFlow { today }
                .flatMapLatest { day ->
                    database.monthOverviewUpdates(
                        on = day,
                        list = entryList,
                    )
                }.collect { overview = it }
        }
    }

    fun startEditing(target: Target) {
        calculator = AmountCalculator(amount = amount(target.categoryId) ?: 0)
        editing = target

        task.clear()
    }

    fun cancelEditing() {
        editing = null
    }

    fun choose(suggestion: Suggestion) {
        calculator = AmountCalculator(amount = suggestion.amount)
    }

    fun press(key: AmountCalculator.Key) {
        calculator = calculator.press(key)
    }

    suspend fun save() {
        if (!canSave) {
            return
        }

        setBudget(calculator.amount)
    }

    suspend fun finishEditing() {
        if (!canSave || calculator.amount == editingAmount) {
            cancelEditing()
            return
        }

        setBudget(calculator.amount)
    }

    suspend fun clear(): Cleared? {
        val target = editing ?: return null
        val amount = editingAmount ?: return null
        val month = month ?: return null

        if (!setBudget(null)) {
            return null
        }

        return Cleared(
            target = target,
            amount = amount,
            month = month,
        )
    }

    suspend fun restore(cleared: Cleared) {
        task.attempt(failure = ModelTask.restoreFailed) {
            database.setBudget(
                amount = cleared.amount,
                categoryId = cleared.target.categoryId,
                from = cleared.month,
            )
        }
    }

    suspend fun setCarryover(isOn: Boolean) {
        saveCarryoverFrom(if (isOn) month else null)
    }

    suspend fun resetCarryover(): YearMonth? {
        val previous = overview?.carryoverFrom ?: return null

        if (carryover == 0L || !saveCarryoverFrom(month)) {
            return null
        }

        return previous
    }

    suspend fun restoreCarryover(from: YearMonth) {
        saveCarryoverFrom(
            start = from,
            failure = ModelTask.restoreFailed,
        )
    }

    fun clearMessage() {
        task.clear()
    }

    private fun spent(
        categoryId: Identifier<EntryCategory>?,
        month: YearMonth,
    ): Long = spentByCategory(month)[categoryId] ?: 0L

    private fun spentByCategory(month: YearMonth): Map<Identifier<EntryCategory>?, Long> {
        val overview = overview ?: return emptyMap()
        val period = month.period(startingOn = overview.monthStartDay)

        val expenses = overview.list?.days
            ?.within(period)
            .orEmpty()
            .flatMap { it.entries }
            .filter { it.type == Entry.Kind.expense }

        val byCategory = expenses
            .filter { it.categoryId != null }
            .groupBy { it.categoryId }
            .mapValues { (_, entries) -> entries.sumOf { it.amount.toLong() } }

        return byCategory + (null to expenses.sumOf { it.amount.toLong() })
    }

    private fun averageSpent(categoryId: Identifier<EntryCategory>?): Long {
        val overview = overview ?: return 0L
        val month = month ?: return 0L
        val firstDate = overview.list?.days?.minOfOrNull { it.date } ?: return 0L

        val months = (1..AVERAGE_MONTHS)
            .map { month.adding(months = -it) }
            .filter { it.period(startingOn = overview.monthStartDay).endInclusive >= firstDate }

        if (months.size < 2) {
            return 0L
        }

        val total = months.sumOf { month ->
            spent(
                categoryId = categoryId,
                month = month,
            )
        }
        val unit = months.size.toLong() * AVERAGE_UNIT

        return (total + unit - 1) / unit * AVERAGE_UNIT
    }

    private suspend fun setBudget(amount: Int?): Boolean {
        val target = editing ?: return false
        val month = month ?: return false

        val saved = task.attempt(failure = SAVE_FAILED) {
            database.setBudget(
                amount = amount,
                categoryId = target.categoryId,
                from = month,
            )
        }

        if (saved != null) {
            editing = null
        }

        return saved != null
    }

    private suspend fun saveCarryoverFrom(
        start: YearMonth?,
        failure: String = SAVE_FAILED,
    ): Boolean {
        val saved = task.attempt(failure = failure) {
            database.setSetting(
                key = SettingKey.budgetCarryoverFrom,
                to = start,
            )
        }

        return saved != null
    }

    private companion object {
        const val SAVE_FAILED = "予算を保存できませんでした"
        const val AVERAGE_MONTHS = 3
        const val AVERAGE_UNIT = 100
    }
}
