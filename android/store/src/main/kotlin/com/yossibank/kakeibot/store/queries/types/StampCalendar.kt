package com.yossibank.kakeibot.store.queries.types

import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.icon.CalendarStamp
import com.yossibank.kakeibot.core.concepts.icon.Icon
import com.yossibank.kakeibot.core.shared.Identifier

data class StampCalendar(
    val stamps: Map<LocalDate, CalendarStamp>,
    val icons: Map<Identifier<Icon>, Icon>,
) {
    data class Tally(
        val icon: Icon,
        val count: Int,
        val lastDate: LocalDate,
    ) {
        val id: Identifier<Icon>
            get() = icon.id
    }

    fun icon(on: LocalDate): Icon? = stamps[on]?.let { icons[it.iconId] }

    fun tallies(range: ClosedRange<LocalDate>): List<Tally> {
        val groups = stamps.values
            .filter { it.date in range }
            .groupBy { it.iconId }

        val tallies = groups.mapNotNull { (iconId, stamps) ->
            val icon = icons[iconId] ?: return@mapNotNull null
            val lastDate = stamps.maxOfOrNull { it.date } ?: return@mapNotNull null

            Tally(
                icon = icon,
                count = stamps.size,
                lastDate = lastDate,
            )
        }

        return tallies.sortedWith(
            compareByDescending<Tally> { it.count }.thenByDescending { it.lastDate },
        )
    }
}
