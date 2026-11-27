package com.yossibank.kakeibot.featuremodels.screens.main

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.yossibank.kakeibot.core.concepts.date.LocalDate
import com.yossibank.kakeibot.core.concepts.notification.PlannedNotification
import com.yossibank.kakeibot.core.concepts.recurring.Recurring
import com.yossibank.kakeibot.core.shared.Identifier
import com.yossibank.kakeibot.featuremodels.shared.model.ForegroundReturn
import com.yossibank.kakeibot.featuremodels.shared.model.ObservationRound
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenEditable
import com.yossibank.kakeibot.featuremodels.shared.model.ScreenPerforming
import com.yossibank.kakeibot.featuremodels.shared.model.Shown
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
    val state = State(TabSelection(tab, visitedTabs), sheet)

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

    data class TabSelection(
        val current: Tab = Tab.Home,
        val visited: Set<Tab> = setOf(Tab.Home),
    ) {
        fun selected(tab: Tab): TabSelection = TabSelection(
            current = tab,
            visited = visited + tab,
        )
    }

    class Presented(
        sheet: Sheet?,
    ) : ScreenEditable {
        val sheet = Shown(sheet)

        private var settingsRound = 0

        internal fun openSettings(recurring: Identifier<Recurring>) {
            settingsRound += 1

            sheet.show(
                Sheet.Settings(
                    recurring = recurring,
                    round = settingsRound,
                ),
            )
        }
    }

    class Notices {
        var round: Int by mutableIntStateOf(0)
            private set

        fun next() {
            round += 1
        }
    }

    class State(
        tabs: TabSelection,
        sheet: Sheet?,
    ) {
        val presented = Presented(sheet)
        val notices = Notices()

        var tabs: TabSelection by mutableStateOf(tabs)
            private set

        val observation = ObservationRound()

        private val foreground = ForegroundReturn()

        fun select(tab: Tab) {
            tabs = tabs.selected(tab)
        }

        fun restartObservation() {
            observation.restart()
        }

        fun changeScene(to: ForegroundReturn.Phase) {
            if (foreground.receive(to)) {
                restartObservation()
            }
        }

        fun hideTabNotices() {
            notices.next()
        }

        internal fun openSettings(recurring: Identifier<Recurring>) {
            presented.openSettings(recurring)
        }
    }

    private class Dependencies(
        val closeDelay: Duration,
    )

    suspend fun open(route: PlannedNotification.Route) {
        if (state.presented.sheet.current != null) {
            closeSheet()
        }

        when (route) {
            is PlannedNotification.Route.Recurring -> {
                state.openSettings(recurring = route.id)
            }

            is PlannedNotification.Route.Entry -> {
                state.select(Tab.Home)
                state.presented.sheet.show(Sheet.Entry(editing = null, date = route.date))
            }

            else -> {
                state.select(Tab.Home)
            }
        }
    }

    fun openEntry(editing: Identifier<Record>?) {
        state.presented.sheet.show(Sheet.Entry(editing = editing))
    }

    private suspend fun closeSheet() {
        state.presented.sheet.closeAll()
        delay(dependencies.closeDelay)
    }

    companion object {
        val sheetCloseDelay: Duration = 600.milliseconds
    }
}
