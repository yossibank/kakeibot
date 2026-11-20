package com.yossibank.kakeibot.features.screens.tabs.review.model

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
import com.yossibank.kakeibot.store.database.AppDatabase
import com.yossibank.kakeibot.store.queries.methods.entryListUpdates
import com.yossibank.kakeibot.store.queries.methods.settingUpdates
import com.yossibank.kakeibot.store.queries.types.EntryList
import com.yossibank.kakeibot.store.records.settingkeys.SettingKey
import com.yossibank.kakeibot.store.records.settingkeys.monthStartDay
import com.yossibank.kakeibot.store.records.settingkeys.weekStart
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.launch

class ReviewModel(
    private val database: AppDatabase,
    today: LocalDate,
) {
    data class Row(
        val key: String,
        val icon: Icon?,
        val name: String,
        val color: String?,
        val amount: Long,
        val ratio: Double,
    )

    var today: LocalDate by mutableStateOf(today)

    var scale: ReviewPeriod.Scale by mutableStateOf(ReviewPeriod.Scale.month)
        private set

    var kind: Entry.Kind by mutableStateOf(Entry.Kind.expense)

    private var offset: Int by mutableStateOf(0)

    private var list: EntryList? by mutableStateOf(null)

    private var monthStartDay: MonthStartDay by mutableStateOf(MonthStartDay.first)

    private var weekStart: Weekday by mutableStateOf(Weekday.monday)

    val period: ReviewPeriod
        get() = ReviewPeriod(
            scale = scale,
            containing = today,
            monthStartDay = monthStartDay,
            weekStart = weekStart,
        ).adding(count = offset)

    val title: String
        get() {
            val range = period.range

            return when (scale) {
                ReviewPeriod.Scale.week -> {
                    "${range.start.monthDayText}〜${range.endInclusive.monthDayText}"
                }

                ReviewPeriod.Scale.month -> {
                    val month = range.start.periodMonth(startingOn = monthStartDay)

                    "${month.year}年 ${month.month}月"
                }

                ReviewPeriod.Scale.year -> {
                    "${range.endInclusive.year}年"
                }
            }
        }

    val rangeText: String
        get() {
            val range = period.range
            return "${range.start.monthDayText}〜${range.endInclusive.monthDayText}"
        }

    val summary: ReviewSummary
        get() = ReviewSummary(
            entries = list?.entries ?: emptyList(),
            range = period.range,
        )

    val previousTotal: Long
        get() {
            val previous = ReviewSummary(
                entries = list?.entries ?: emptyList(),
                range = period.comparisonRange(today = today),
            )

            return previous.breakdown(of = kind)?.total ?: 0
        }

    val total: Long
        get() = summary.breakdown(of = kind)?.total ?: 0

    val rows: List<Row>
        get() {
            val list = list ?: return emptyList()
            val breakdown = summary.breakdown(of = kind) ?: return emptyList()

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

    suspend fun observe() {
        coroutineScope {
            launch {
                database.settingUpdates(SettingKey.monthStartDay).collect { monthStartDay = it }
            }

            launch {
                database.settingUpdates(SettingKey.weekStart).collect { weekStart = it }
            }

            launch {
                database.entryListUpdates().collect { list = it }
            }
        }
    }

    fun select(scale: ReviewPeriod.Scale) {
        this.scale = scale
        offset = 0
    }

    fun move(count: Int) {
        offset += count
    }
}
