package com.yossibank.kakeibot.featuremodels.screens.settings.budgets

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
import com.yossibank.kakeibot.core.concepts.setting.SettingsScreen
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.featuremodels.shared.amount.AmountText
import com.yossibank.kakeibot.featuremodels.shared.amount.clamped
import com.yossibank.kakeibot.featuremodels.shared.model.ModelTask
import com.yossibank.kakeibot.featuremodels.shared.period.PeriodText
import com.yossibank.kakeibot.featuremodels.shared.settingsparts.hint.SettingsFoldInput
import com.yossibank.kakeibot.featuremodels.shared.settingsparts.hint.SettingsFoldModel
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
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.launch

class BudgetListModel(
    database: AppDatabase,
    entryList: Flow<EntryList>,
    today: LocalDate,
) : SettingsFoldModel {
    val state = State(today)
    val input = Input()
    val output = Output(input, state)

    private val dependencies = Dependencies(database, entryList)

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

    class State(
        today: LocalDate,
    ) {
        val task = ModelTask()

        var today: LocalDate by mutableStateOf(today)

        var editing: Target? by mutableStateOf(null)
            private set

        var calculator by mutableStateOf(AmountCalculator())
            private set

        fun startEditing(
            target: Target,
            amount: Int,
        ) {
            calculator = AmountCalculator(amount = amount)
            editing = target
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
    }

    class Input {
        var overview: MonthOverview? by mutableStateOf(null)
            internal set

        var categoryList: CategoryList? by mutableStateOf(null)
            internal set

        val hint = SettingsFoldInput.hint(SettingsScreen.budgets)
    }

    class Output(
        internal val input: Input,
        internal val state: State,
    ) {
        val month: YearMonth?
            get() = input.overview?.month

        val periodText: String
            get() = input.overview?.period?.let(PeriodText::range) ?: ""

        val startText: String
            get() = "${month?.month ?: ""}月（$periodText）から使う額"

        val categoriesNote: String
            get() = "合計 ${AmountText.text(amount = categoriesTotal)}"

        val unbudgetedNote: String
            get() = "${unbudgeted.size} カテゴリ"

        val recurringExpense: Long
            get() = input.overview?.recurringExpense ?: 0L

        val recurringText: String
            get() {
                val amount = AmountText.text(amount = recurringExpense.clamped)
                return "この月の固定費は $amount。予算の目安にできます"
            }

        val categories: List<EntryCategory> by derivedStateOf {
            input.categoryList?.categories.orEmpty().filter { category ->
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
            month?.let { spentByCategory(it) }.orEmpty()
        }

        val totalAmount: Int?
            get() = amount(null)

        val isCarryoverOn: Boolean
            get() = input.overview?.carryoverFrom != null

        val carryover: Long
            get() = input.overview?.budgetCarryover ?: 0L

        val categoriesTotal: Int
            get() = categories.sumOf { amount(it.id) ?: 0 }

        val editingAmount: Int?
            get() = state.editing?.let { amount(it.categoryId) }

        val canSave: Boolean
            get() = state.calculator.amount > 0

        val isChanged: Boolean
            get() = state.editing != null && state.calculator.amount != (editingAmount ?: 0)

        val saveTitle: String
            get() = if (canSave) "${month?.month ?: ""}月からこの額にする" else "金額を入れてください"

        fun amount(categoryId: Identifier<EntryCategory>?): Int? {
            val month = month ?: return null
            return input.overview?.budgets?.amount(
                categoryId = categoryId,
                month = month,
            )
        }

        fun spent(categoryId: Identifier<EntryCategory>?): Long = monthSpent[categoryId] ?: 0L

        fun usage(categoryId: Identifier<EntryCategory>?): BudgetUsage? {
            val overview = input.overview ?: return null
            val budget = amount(categoryId) ?: return null

            return BudgetUsage(
                budget = budget,
                carryover = if (categoryId == null) carryover else 0L,
                spent = spent(categoryId),
                today = overview.today,
                periodEnd = overview.period.endInclusive,
            )
        }

        fun icon(category: EntryCategory) = input.categoryList?.icons?.get(category.iconId)
    }

    private class Dependencies(
        val database: AppDatabase,
        val entryList: Flow<EntryList>,
    )

    @OptIn(ExperimentalCoroutinesApi::class)
    suspend fun observe() {
        val database = dependencies.database

        coroutineScope {
            launch {
                observe(database.categoryListUpdates()) { input.categoryList = it }
            }

            val overviews = snapshotFlow { state.today }.flatMapLatest { day ->
                database.monthOverviewUpdates(
                    on = day,
                    list = dependencies.entryList,
                )
            }

            observe(overviews) { input.overview = it }
        }
    }

    override suspend fun loadFold(fold: SettingsFoldInput) {
        fold.load(from = dependencies.database)
    }

    override suspend fun setFold(
        fold: SettingsFoldInput,
        isClosed: Boolean,
    ) {
        fold.save(
            isClosed = isClosed,
            to = dependencies.database,
        )
    }

    fun startEditing(target: Target) {
        state.startEditing(
            target = target,
            amount = output.amount(target.categoryId) ?: 0,
        )
    }

    suspend fun save() {
        if (!output.canSave) {
            return
        }

        setBudget(state.calculator.amount)
    }

    suspend fun finishEditing() {
        if (!output.canSave || state.calculator.amount == output.editingAmount) {
            state.cancelEditing()
            return
        }

        setBudget(state.calculator.amount)
    }

    suspend fun clear(): Cleared? {
        val target = state.editing ?: return null
        val amount = output.editingAmount ?: return null
        val month = output.month ?: return null

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
        state.task.attempt(failure = ModelTask.restoreFailed) {
            dependencies.database.setBudget(
                amount = cleared.amount,
                categoryId = cleared.target.categoryId,
                from = cleared.month,
            )
        }
    }

    suspend fun setCarryover(isOn: Boolean) {
        saveCarryoverFrom(if (isOn) output.month else null)
    }

    suspend fun resetCarryover(): YearMonth? {
        val previous = input.overview?.carryoverFrom ?: return null

        if (output.carryover == 0L || !saveCarryoverFrom(output.month)) {
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

    private suspend fun setBudget(amount: Int?): Boolean {
        val target = state.editing ?: return false
        val month = output.month ?: return false

        val saved = state.task.attempt(failure = SAVE_FAILED) {
            dependencies.database.setBudget(
                amount = amount,
                categoryId = target.categoryId,
                from = month,
            )
        }

        if (saved != null) {
            state.cancelEditing()
        }

        return saved != null
    }

    private suspend fun <Value> observe(
        values: Flow<Value>,
        receive: suspend (Value) -> Unit,
    ) {
        state.task.observe(
            values = values,
            failure = loadFailedMessage,
            receive = receive,
        )
    }

    private suspend fun saveCarryoverFrom(
        start: YearMonth?,
        failure: String = SAVE_FAILED,
    ): Boolean {
        val saved = state.task.attempt(failure = failure) {
            dependencies.database.setSetting(
                key = SettingKey.budgetCarryoverFrom,
                to = start,
            )
        }

        return saved != null
    }

    companion object {
        const val loadFailedMessage = "予算を読めませんでした"

        private const val SAVE_FAILED = "予算を保存できませんでした"
    }
}
