package com.yossibank.kakeibot.featuremodels.screens.tabs.review.model

import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.yossibank.kakeibot.core.concepts.category.EntryCategory
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.date.MonthStartDay
import com.yossibank.kakeibot.core.concepts.date.Weekday
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.concepts.review.ReviewKind
import com.yossibank.kakeibot.core.concepts.review.ReviewPeriod
import com.yossibank.kakeibot.core.concepts.review.ReviewSummary
import com.yossibank.kakeibot.featuremodels.screens.tabs.review.parts.ReviewText
import com.yossibank.kakeibot.featuremodels.screens.tabs.review.parts.entryType
import com.yossibank.kakeibot.featuremodels.shared.amount.AmountText
import com.yossibank.kakeibot.featuremodels.shared.amount.clamped
import com.yossibank.kakeibot.featuremodels.shared.model.ModelTask
import com.yossibank.kakeibot.featuremodels.shared.model.ObservationRound
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenParts
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenPerforming
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
import kotlin.math.abs

class ReviewModel(
    parts: ScreenParts,
    today: LocalDate,
    round: ObservationRound,
) : ScreenPerforming {
    val state = State(today)
    val input = Input()
    val output = Output(input, state)

    private val dependencies = Dependencies(parts.database, parts.entryList, round)

    data class Row(
        val key: String,
        val icon: Icon?,
        val name: String,
        val color: String?,
        val amount: Long,
        val ratio: Double,
        val percent: String?,
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
        val task = ModelTask()

        var today: LocalDate by mutableStateOf(today)

        var offset: Int by mutableStateOf(0)
            private set

        var isListFailed: Boolean by mutableStateOf(false)
            internal set

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

        var weekStart: Weekday by mutableStateOf(Weekday.sunday)
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
                        PeriodText.range(
                            period = range,
                            today = state.today,
                        )
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

        val hasPreviousEntries: Boolean
            get() {
                val range = period.comparisonRange(today = state.today)
                return input.list?.entries.orEmpty().any { it.date in range }
            }

        val comparisonText: String
            get() {
                if (!hasPreviousEntries) {
                    return "比べる記録がまだありません"
                }

                val previous = ReviewText.previousName(
                    scale = input.scale,
                    isPartial = state.today in period.range,
                )

                val amount = AmountText.text(abs(change).clamped)

                return when {
                    change > 0 -> "${previous}より $amount 多い"
                    change < 0 -> "${previous}より $amount 少ない"
                    else -> "${previous}と同じ"
                }
            }

        val change: Long
            get() = total - previousTotal

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

                val shares = breakdown.byCategory
                    .mapNotNull { (id, amount) -> list.categories[id]?.let { it to amount } }
                    .sortedWith(
                        compareByDescending<Pair<EntryCategory, Long>> { it.second }
                            .thenBy { it.first.sortOrder },
                    )

                val percents = ReviewText.shares(shares.map { it.second })

                return shares.zip(percents) { (category, amount), percent ->
                    val icon = list.icons[category.iconId]

                    Row(
                        key = category.id.toString(),
                        icon = icon,
                        name = category.name,
                        color = icon?.color,
                        amount = amount,
                        ratio = amount.toDouble() / breakdown.total.toDouble(),
                        percent = percent,
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
        val round: ObservationRound,
    )

    suspend fun observe() {
        dependencies.round.each { observeAll() }
    }

    fun retry() {
        dependencies.round.restart()
    }

    private suspend fun observeAll() {
        loadSelection()

        val database = dependencies.database

        coroutineScope {
            launch {
                observe(database.settingUpdates(SettingKey.monthStartDay)) {
                    input.monthStartDay = it
                }
            }

            launch {
                observe(database.settingUpdates(SettingKey.weekStart)) { input.weekStart = it }
            }

            launch {
                state.task.observe(
                    values = dependencies.entryList,
                    failure = loadFailedMessage,
                    failing = { state.isListFailed = it },
                ) { input.list = it }
            }
        }
    }

    suspend fun loadSelection() {
        val database = dependencies.database

        state.task.attempt(failure = loadFailedMessage) {
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

        state.task.attempt(failure = ModelTask.saveFailed) {
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

    companion object {
        const val loadFailedMessage = "記録を読めませんでした"
    }
}
