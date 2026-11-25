package com.yossibank.kakeibot.featuremodels.screens.main

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.notification.PlannedNotification
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenPerforming
import kotlinx.coroutines.delay
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import com.yossibank.kakeibot.core.concepts.entry.Entry as Record

class MainModel(
    tab: Tab = Tab.Home,
    visitedTabs: Set<Tab> = setOf(Tab.Home),
    sheet: Sheet? = null,
    closeDelay: Duration = sheetCloseDelay,
) : ScreenPerforming {
    val state = State(tab, visitedTabs, sheet)

    private val dependencies = Dependencies(closeDelay)

    enum class Tab(
        val title: String,
    ) {
        Home("ホーム"),
        Records("記録"),
        Review("振り返り"),
        Assets("資産"),
    }

    sealed interface Sheet {
        data object Budget : Sheet

        data class Entry(
            val editing: Identifier<Record>?,
            val date: LocalDate? = null,
        ) : Sheet

        data class Settings(
            val recurring: Identifier<Recurring>? = null,
            val round: Int = 0,
        ) : Sheet
    }

    class State(
        tab: Tab,
        visitedTabs: Set<Tab>,
        sheet: Sheet?,
    ) {
        var sheet: Sheet? by mutableStateOf(sheet)

        var tab: Tab by mutableStateOf(tab)
            private set

        var visitedTabs: Set<Tab> by mutableStateOf(visitedTabs)
            private set

        private var round = 0

        fun select(tab: Tab) {
            this.tab = tab
            visitedTabs = visitedTabs + tab
        }

        internal fun openSettings(recurring: Identifier<Recurring>) {
            round += 1

            sheet = Sheet.Settings(
                recurring = recurring,
                round = round,
            )
        }
    }

    private class Dependencies(
        val closeDelay: Duration,
    )

    suspend fun open(route: PlannedNotification.Route) {
        if (state.sheet != null) {
            closeSheet()
        }

        when (route) {
            is PlannedNotification.Route.Recurring -> {
                state.openSettings(recurring = route.id)
            }

            is PlannedNotification.Route.Entry -> {
                state.select(Tab.Home)
                state.sheet = Sheet.Entry(editing = null, date = route.date)
            }

            else -> {
                state.select(Tab.Home)
            }
        }
    }

    fun openEntry(editing: Identifier<Record>?) {
        state.sheet = Sheet.Entry(editing = editing)
    }

    private suspend fun closeSheet() {
        state.sheet = null
        delay(dependencies.closeDelay)
    }

    companion object {
        val sheetCloseDelay: Duration = 600.milliseconds
    }
}
