package com.yossibank.kakeibot.featuremodels.screens.settings.budgets

import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshotFlow
import com.yossibank.kakeibot.core.concepts.budget.amount
import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.date.YearMonth
import com.yossibank.kakeibot.core.concepts.entry.AmountCalculator
import com.yossibank.kakeibot.core.concepts.setting.SettingsScreen
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.featuremodels.shared.model.EditFlow
import com.yossibank.kakeibot.featuremodels.shared.model.EditFlowSource
import com.yossibank.kakeibot.featuremodels.shared.model.ErrorNotice
import com.yossibank.kakeibot.featuremodels.shared.model.ModelTask
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenEditable
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenParts
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenWait
import com.yossibank.kakeibot.featuremodels.shared.model.UndoNotice
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
    parts: ScreenParts,
    today: LocalDate,
) : SettingsFoldModel {
    val state = State(parts.wait)
    val input = Input(today)
    val output = Output(input, state)
    val flow = EditFlow(task = state.task, source = Source())

    private val dependencies = Dependencies(parts.database, parts.entryList)

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

    class Notices(
        wait: ScreenWait,
    ) {
        val error = ErrorNotice(wait)
        val cleared = UndoNotice<Cleared>(wait)
        val resetFrom = UndoNotice<YearMonth>(wait)
    }

    class Submodels {
        var calculator by mutableStateOf(AmountCalculator())
            internal set
    }

    class Presented : ScreenEditable {
        var editing: Target? by mutableStateOf(null)
            internal set
    }

    class State(
        wait: ScreenWait,
    ) {
        val notices = Notices(wait)
        val task = ModelTask(notices.error)
        val submodels = Submodels()
        val presented = Presented()

        fun startEditing(
            target: Target,
            amount: Int,
        ) {
            submodels.calculator = AmountCalculator(amount = amount)
            presented.editing = target
        }

        fun cancelEditing() {
            presented.editing = null
        }

        fun choose(suggestion: Suggestion) {
            submodels.calculator = AmountCalculator(amount = suggestion.amount)
        }

        fun press(key: AmountCalculator.Key) {
            submodels.calculator = submodels.calculator.press(key)
        }
    }

    class Input(
        today: LocalDate,
    ) {
        var today: LocalDate by mutableStateOf(today)
            internal set

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

        val recurringExpense: Long
            get() = input.overview?.recurringExpense ?: 0L

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

        val totalAmount: Int?
            get() = amount(null)

        val isCarryoverOn: Boolean
            get() = input.overview?.carryoverFrom != null

        val carryover: Long
            get() = input.overview?.budgetCarryover ?: 0L

        val categoriesTotal: Int
            get() = categories.sumOf { amount(it.id) ?: 0 }

        val editingAmount: Int?
            get() = state.presented.editing?.let { amount(it.categoryId) }

        val canSave: Boolean
            get() = state.submodels.calculator.amount > 0

        val isChanged: Boolean
            get() = state.presented.editing != null &&
                state.submodels.calculator.amount != (editingAmount ?: 0)

        fun amount(categoryId: Identifier<EntryCategory>?): Int? {
            val month = month ?: return null

            return input.overview?.budgets?.amount(
                categoryId = categoryId,
                month = month,
            )
        }

        fun spent(categoryId: Identifier<EntryCategory>?): Long = monthSpent[categoryId] ?: 0L

        fun icon(category: EntryCategory) = input.categoryList?.icons?.get(category.iconId)

        private val monthSpent: Map<Identifier<EntryCategory>?, Long> by derivedStateOf {
            month?.let { spentByCategory(it) }.orEmpty()
        }
    }

    private class Dependencies(
        val database: AppDatabase,
        val entryList: Flow<EntryList>,
    )

    private inner class Source : EditFlowSource<Unit> {
        override val isEditing: Boolean
            get() = output.editingAmount != null

        override val isChanged: Boolean
            get() = output.isChanged

        override val problem: String?
            get() = if (output.canSave) null else "金額を入れてください"

        override val readyTitle: String
            get() = "${output.month?.month ?: ""}月からこの額にする"

        override suspend fun store(): Unit? =
            if (setBudget(state.submodels.calculator.amount)) Unit else null
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

    @OptIn(ExperimentalCoroutinesApi::class)
    suspend fun observe() {
        val database = dependencies.database

        coroutineScope {
            launch {
                observe(database.categoryListUpdates()) { input.categoryList = it }
            }

            val overviews = snapshotFlow { input.today }.flatMapLatest { day ->
                database.monthOverviewUpdates(
                    on = day,
                    list = dependencies.entryList,
                )
            }

            observe(overviews) { input.overview = it }
        }
    }

    fun startEditing(target: Target) {
        state.startEditing(
            target = target,
            amount = output.amount(target.categoryId) ?: 0,
        )
    }

    fun setToday(today: LocalDate) {
        input.today = today
    }

    suspend fun finishEditing() {
        if (!output.canSave || state.submodels.calculator.amount == output.editingAmount) {
            state.cancelEditing()
            return
        }

        setBudget(state.submodels.calculator.amount)
    }

    suspend fun clear(): Cleared? {
        val target = state.presented.editing ?: return null
        val amount = output.editingAmount ?: return null
        val month = output.month ?: return null

        if (!setBudget(null)) {
            return null
        }

        val cleared = Cleared(
            target = target,
            amount = amount,
            month = month,
        )

        state.notices.cleared.show(cleared)

        return cleared
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

        state.notices.resetFrom.show(previous)

        return previous
    }

    suspend fun restoreCarryover(from: YearMonth) {
        saveCarryoverFrom(
            start = from,
            failure = ModelTask.restoreFailed,
        )
    }

    private suspend fun setBudget(amount: Int?): Boolean {
        val target = state.presented.editing ?: return false
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
