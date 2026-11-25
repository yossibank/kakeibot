package com.yossibank.kakeibot.featuremodels.screens.tabs.review.model

import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.date.MonthStartDay
import com.yossibank.kakeibot.core.concepts.date.Weekday
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.concepts.review.ReviewKind
import com.yossibank.kakeibot.core.concepts.review.ReviewPeriod
import com.yossibank.kakeibot.core.concepts.review.ReviewSummary
import com.yossibank.kakeibot.featuremodels.screens.tabs.review.parts.entryType
import com.yossibank.kakeibot.featuremodels.shared.model.ModelTask
import com.yossibank.kakeibot.featuremodels.shared.period.PeriodText
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.queries.methods.setting
import com.yossibank.kakeibot.store.queries.methods.settingUpdates
import com.yossibank.kakeibot.store.queries.types.EntryList
import com.yossibank.kakeibot.store.records.settingkeys.SettingKey
import com.yossibank.kakeibot.store.records.settingkeys.monthStartDay
import com.yossibank.kakeibot.store.records.settingkeys.reviewKind
import com.yossibank.kakeibot.store.records.settingkeys.reviewScale
import com.yossibank.kakeibot.store.records.settingkeys.weekStart
import com.yossibank.kakeibot.store.writes.methods.setSetting
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.launch

class ReviewModel(
    database: AppDatabase,
    entryList: Flow<EntryList>,
    today: LocalDate,
) {
    val state = State(today)
    val input = Input()
    val output = Output(input, state)

    private val dependencies = Dependencies(database, entryList)

    data class Row(
        val key: String,
        val icon: Icon?,
        val name: String,
        val color: String?,
        val amount: Long,
        val ratio: Double,
    )

    data class BalanceBar(
        val title: String,
        val type: Entry.Kind,
        val amount: Long,
        val ratio: Double,
    )

    class State(
        today: LocalDate,
    ) {
        var today: LocalDate by mutableStateOf(today)

        var offset: Int by mutableStateOf(0)
            private set

        fun move(count: Int) {
            if (offset + count > 0) {
                return
            }

            offset += count
        }

        internal fun restart() {
            offset = 0
        }
    }

    class Input {
        var scale: ReviewPeriod.Scale by mutableStateOf(ReviewPeriod.Scale.month)
            internal set

        var kind: ReviewKind by mutableStateOf(ReviewKind.expense)
            internal set

        var list: EntryList? by mutableStateOf(null)
            internal set

        var monthStartDay: MonthStartDay by mutableStateOf(MonthStartDay.first)
            internal set

        var weekStart: Weekday by mutableStateOf(Weekday.monday)
            internal set
    }

    class Output(
        private val input: Input,
        private val state: State,
    ) {
        val period: ReviewPeriod
            get() = ReviewPeriod(
                scale = input.scale,
                containing = state.today,
                monthStartDay = input.monthStartDay,
                weekStart = input.weekStart,
            ).adding(count = state.offset)

        val canMoveForward: Boolean
            get() = state.offset < 0

        val title: String
            get() {
                val range = period.range

                return when (input.scale) {
                    ReviewPeriod.Scale.week -> {
                        PeriodText.range(range)
                    }

                    ReviewPeriod.Scale.month -> {
                        val month = range.start.periodMonth(startingOn = input.monthStartDay)

                        "${month.year}年 ${month.month}月"
                    }

                    ReviewPeriod.Scale.year -> {
                        "${range.endInclusive.year}年"
                    }
                }
            }

        val rangeText: String
            get() = PeriodText.range(period.range)

        val summary: ReviewSummary by derivedStateOf {
            ReviewSummary(
                entries = input.list?.entries ?: emptyList(),
                range = period.range,
            )
        }

        val previousTotal: Long
            get() {
                val previous = ReviewSummary(
                    entries = input.list?.entries ?: emptyList(),
                    range = period.comparisonRange(today = state.today),
                )

                return total(of = previous)
            }

        val total: Long
            get() = total(of = summary)

        val rows: List<Row>
            get() {
                val list = input.list ?: return emptyList()
                val type = input.kind.entryType ?: return emptyList()
                val breakdown = summary.breakdown(of = type) ?: return emptyList()

                if (breakdown.total <= 0) {
                    return emptyList()
                }

                return breakdown.byCategory
                    .entries
                    .sortedByDescending { it.value }
                    .map { (id, amount) ->
                        val category = list.categories[id]
                        val icon = category?.let { list.icons[it.iconId] }

                        Row(
                            key = id.toString(),
                            icon = icon,
                            name = category?.name ?: "未分類",
                            color = icon?.color,
                            amount = amount,
                            ratio = amount.toDouble() / breakdown.total.toDouble(),
                        )
                    }
            }

        val balanceBars: List<BalanceBar>
            get() {
                if (input.kind != ReviewKind.balance) {
                    return emptyList()
                }

                val income = summary.income.total
                val expense = summary.expense.total
                val largest = maxOf(income, expense)

                return listOf(
                    Triple("収入", Entry.Kind.income, income),
                    Triple("支出", Entry.Kind.expense, expense),
                ).map { (title, type, amount) ->
                    BalanceBar(
                        title = title,
                        type = type,
                        amount = amount,
                        ratio = if (largest > 0) amount.toDouble() / largest.toDouble() else 0.0,
                    )
                }
            }

        private fun total(of: ReviewSummary): Long = when (input.kind) {
            ReviewKind.expense -> of.expense.total
            ReviewKind.income -> of.income.total
            ReviewKind.balance -> of.balance
        }
    }

    private class Dependencies(
        val database: AppDatabase,
        val entryList: Flow<EntryList>,
    )

    suspend fun observe() {
        loadSelection()

        val database = dependencies.database

        coroutineScope {
            launch {
                database.settingUpdates(SettingKey.monthStartDay).collect {
                    input.monthStartDay = it
                }
            }

            launch {
                database.settingUpdates(SettingKey.weekStart).collect { input.weekStart = it }
            }

            launch {
                dependencies.entryList.collect { input.list = it }
            }
        }
    }

    suspend fun loadSelection() {
        val database = dependencies.database

        ModelTask.quiet {
            input.scale = database.setting(SettingKey.reviewScale)
            input.kind = database.setting(SettingKey.reviewKind)
        }
    }

    fun setScale(scale: ReviewPeriod.Scale) {
        state.restart()
        input.scale = scale
    }

    fun setKind(kind: ReviewKind) {
        input.kind = kind
    }

    suspend fun saveSelection() {
        val database = dependencies.database

        ModelTask.quiet {
            database.setSetting(
                key = SettingKey.reviewScale,
                to = input.scale,
            )
            database.setSetting(
                key = SettingKey.reviewKind,
                to = input.kind,
            )
        }
    }
}
