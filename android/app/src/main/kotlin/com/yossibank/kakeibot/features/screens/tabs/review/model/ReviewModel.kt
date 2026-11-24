package com.yossibank.kakeibot.features.screens.tabs.review.model

import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.date.MonthStartDay
import com.yossibank.kakeibot.core.concepts.date.Weekday
import com.yossibank.kakeibot.core.concepts.entry.Entry
import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.concepts.review.ReviewPeriod
import com.yossibank.kakeibot.core.concepts.review.ReviewSummary
import com.yossibank.kakeibot.features.shared.period.PeriodText
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.queries.methods.settingUpdates
import com.yossibank.kakeibot.store.queries.types.EntryList
import com.yossibank.kakeibot.store.records.settingkeys.SettingKey
import com.yossibank.kakeibot.store.records.settingkeys.monthStartDay
import com.yossibank.kakeibot.store.records.settingkeys.weekStart
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

    class State(
        today: LocalDate,
    ) {
        var today: LocalDate by mutableStateOf(today)

        var scale: ReviewPeriod.Scale by mutableStateOf(ReviewPeriod.Scale.month)
            private set

        var kind: Entry.Kind by mutableStateOf(Entry.Kind.expense)

        var offset: Int by mutableStateOf(0)
            private set

        fun select(scale: ReviewPeriod.Scale) {
            this.scale = scale
            offset = 0
        }

        fun move(count: Int) {
            offset += count
        }
    }

    class Input {
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
                scale = state.scale,
                containing = state.today,
                monthStartDay = input.monthStartDay,
                weekStart = input.weekStart,
            ).adding(count = state.offset)

        val title: String
            get() {
                val range = period.range

                return when (state.scale) {
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

                return previous.breakdown(of = state.kind)?.total ?: 0
            }

        val total: Long
            get() = summary.breakdown(of = state.kind)?.total ?: 0

        val rows: List<Row>
            get() {
                val list = input.list ?: return emptyList()
                val breakdown = summary.breakdown(of = state.kind) ?: return emptyList()

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
    }

    private class Dependencies(
        val database: AppDatabase,
        val entryList: Flow<EntryList>,
    )

    suspend fun observe() {
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
}
